# frozen_string_literal: true

require "active_storage/service/db_service_rails60"
require "active_storage/service/db_service_rails61"
require "active_storage/service/db_service_rails70"

module ActiveStorage
  class Service::DBService < Service
    include ActiveStorage::DBServiceRails70

    DEFAULT_RETRY_OPTIONS = {
      max_attempts: 3,
      base_delay: 0.1,
      max_delay: 2.0,
      retryable_errors: [
        ActiveRecord::ConnectionFailed,
        ActiveRecord::StatementTimeout
      ].freeze
    }.freeze

    MINIMUM_CHUNK_SIZE = 1

    def initialize(public: false, chunk_size: nil, **)
      @chunk_size = [chunk_size || ENV.fetch("ASDB_CHUNK_SIZE") { 1.megabyte }.to_i, MINIMUM_CHUNK_SIZE].max
      @max_size = ENV.fetch("ASDB_MAX_FILE_SIZE", nil)&.to_i
      @public = public
    end

    def upload(key, io, checksum: nil, **)
      instrument :upload, key: key, checksum: checksum do
        data = io.read
        if @max_size && data.bytesize > @max_size
          raise ArgumentError, "File size exceeds the maximum allowed size of #{@max_size} bytes"
        end

        if checksum
          digest = Digest::MD5.base64digest(data)
          raise ActiveStorage::IntegrityError unless digest == checksum
        end
        retry_on_failure { ::ActiveStorageDB::File.create!(ref: key, data: data) }
      end
    end

    def download(key, &block)
      if block_given?
        instrument :streaming_download, key: key do
          stream(key, &block)
        end
      else
        instrument :download, key: key do
          retrieve_file(key)
        end
      end
    end

    def download_chunk(key, range)
      instrument :download_chunk, key: key, range: range do
        chunk = if adapter_postgresql? && @chunk_size >= 1.megabyte
                  pg_read_binary(key, range)
                else
                  sql_chunk(key, range)
                end
        raise ActiveStorage::FileNotFoundError unless chunk

        chunk
      end
    end

    def delete(key)
      instrument :delete, key: key do
        comment = "DBService#delete"
        retry_on_failure do
          ::ActiveStorageDB::File.annotate(comment).where(ref: key).delete > 0
        end
      end
    end

    def delete_prefixed(prefix)
      instrument :delete_prefixed, prefix: prefix do
        comment = "DBService#delete_prefixed"
        sanitized_prefix = "#{ActiveRecord::Base.sanitize_sql_like(prefix)}%"
        retry_on_failure do
          ::ActiveStorageDB::File.annotate(comment).where("ref LIKE ?", sanitized_prefix).delete_all
        end
      end
    end

    def exist?(key)
      instrument :exist, key: key do |payload|
        comment = "DBService#exist?"
        result = ::ActiveStorageDB::File.annotate(comment).exists?(ref: key)
        payload[:exist] = result
        result
      end
    end

    def url_for_direct_upload(key, expires_in:, content_type:, content_length:, checksum:, custom_metadata: {})
      instrument :url, key: key do |payload|
        verified_token_with_expiration = ActiveStorage.verifier.generate(
          {
            key: key,
            content_type: content_type,
            content_length: content_length,
            checksum: checksum,
            service_name: service_name_for_token
          },
          expires_in: expires_in,
          purpose: :blob_token
        )

        url_helpers.update_service_url(verified_token_with_expiration, url_options).tap do |generated_url|
          payload[:url] = generated_url
        end
      end
    end

    def headers_for_direct_upload(_key, content_type:, **)
      { "Content-Type" => content_type }
    end

    private

    def retry_options
      @retry_options ||= {
        max_attempts: 3,
        base_delay: 0.1,
        max_delay: 2.0,
        retryable_errors: default_retryable_errors
      }
    end

    def retry_on_failure
      attempts = 0
      max_attempts = retry_options[:max_attempts]
      base_delay = retry_options[:base_delay]
      max_delay = retry_options[:max_delay]
      retryable_errors = retry_options[:retryable_errors]

      begin
        yield
      rescue *retryable_errors
        attempts += 1
        raise if attempts >= max_attempts

        delay = [base_delay * (2**attempts), max_delay].min
        sleep(delay)
        retry
      end
    end

    def default_retryable_errors
      errors = [
        ActiveRecord::ConnectionFailed,
        ActiveRecord::StatementTimeout
      ]
      errors << PG::ConnectionBad if defined?(PG::ConnectionBad)
      errors
    end

    def service_name_for_token
      name.presence || "db"
    end

    def adapter_sqlite?
      @adapter_sqlite ||= active_storage_db_adapter_name == "SQLite"
    end

    def adapter_sqlserver?
      @adapter_sqlserver ||= active_storage_db_adapter_name == "SQLServer"
    end

    def adapter_postgresql?
      @adapter_postgresql ||= active_storage_db_adapter_name == "PostgreSQL"
    end

    def adapter_mysql?
      @adapter_mysql ||= active_storage_db_adapter_name == "Mysql2"
    end

    def active_storage_db_adapter_name
      if ActiveStorageDB::File.respond_to?(:lease_connection)
        ActiveStorageDB::File.lease_connection.adapter_name
      else
        ActiveStorageDB::File.connection.adapter_name
      end
    end

    def generate_url(key, expires_in:, filename:, content_type:, disposition:)
      content_disposition = content_disposition_with(type: disposition, filename: filename)
      verified_key_with_expiration = ActiveStorage.verifier.generate(
        {
          key: key,
          disposition: content_disposition,
          content_type: content_type,
          service_name: service_name_for_token
        },
        expires_in: expires_in,
        purpose: :blob_key
      )

      current_uri = URI.parse(current_host)
      url_helpers.service_url(
        verified_key_with_expiration,
        protocol: current_uri.scheme,
        host: current_uri.host,
        port: current_uri.port,
        disposition: content_disposition,
        content_type: content_type,
        filename: filename
      )
    end

    def retrieve_file(key)
      file = object_for(key)
      raise ActiveStorage::FileNotFoundError unless file

      file.data
    end

    def object_for(key, fields: nil)
      comment = "DBService#object_for"
      scope = ::ActiveStorageDB::File.annotate(comment)
      scope = scope.select(fields) if fields
      scope.find_by(ref: key)
    end

    def stream(key)
      size = object_for(key, fields: data_size)&.size || raise(ActiveStorage::FileNotFoundError)
      (size / @chunk_size.to_f).ceil.times.each do |i|
        range = (i * @chunk_size)..(((i + 1) * @chunk_size) - 1)
        yield download_chunk(key, range)
      end
    end

    def sql_chunk(key, range)
      from = range.begin + 1
      size = range.size
      args = adapter_sqlserver? || adapter_sqlite? ? "data, #{from}, #{size}" : "data FROM #{from} FOR #{size}"
      record = object_for(key, fields: "SUBSTRING(#{args}) AS chunk")
      record&.chunk
    end

    def pg_read_binary(key, range)
      from = range.begin + 1
      size = range.size
      comment = "DBService#pg_read_binary"
      ::ActiveStorageDB::File.annotate(comment).where(ref: key).pick("get_byte(data, (#{from} - 1) + generate_series(0, #{size} - 1))")
    rescue ActiveRecord::StatementInvalid
      sql_chunk(key, range)
    end

    def data_size
      if adapter_sqlserver?
        "DATALENGTH(data) AS size"
      elsif adapter_sqlite?
        "LENGTH(data) AS size"
      else
        "OCTET_LENGTH(data) AS size"
      end
    end

    def url_helpers
      @url_helpers ||= ::ActiveStorageDB::Engine.routes.url_helpers
    end
  end
end
