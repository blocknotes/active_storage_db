# frozen_string_literal: true

require 'active_storage/service/db_service_rails60'
require 'active_storage/service/db_service_rails61'
require 'active_storage/service/db_service_rails70'

module ActiveStorage
  # Wraps a DB table as an Active Storage service. See ActiveStorage::Service
  # for the generic API documentation that applies to all services.
  class Service::DBService < Service
    # :nocov:
    if Rails::VERSION::MAJOR >= 7
      include ActiveStorage::DBServiceRails70
    elsif Rails::VERSION::MAJOR == 6 && Rails::VERSION::MINOR == 1
      include ActiveStorage::DBServiceRails61
    else
      include ActiveStorage::DBServiceRails60
    end
    # :nocov:

    def initialize(public: false, **)
      @chunk_size = ENV.fetch('ASDB_CHUNK_SIZE') { 1.megabytes }
      @public = public
    end

    def upload(key, io, checksum: nil, **)
      instrument :upload, key: key, checksum: checksum do
        file = ::ActiveStorageDB::File.create!(ref: key, data: io.read)
        ensure_integrity_of(key, checksum) if checksum
        file
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
        from = range.begin + 1
        size = range.size
        args = adapter_sqlserver? ? "data, #{from}, #{size}" : "data FROM #{from} FOR #{size}"
        record = object_for(key, fields: "SUBSTRING(#{args}) AS chunk")
        raise(ActiveStorage::FileNotFoundError) unless record

        record.chunk
      end
    end

    def delete(key)
      instrument :delete, key: key do
        ::ActiveStorageDB::File.find_by(ref: key)&.destroy
        # Ignore files already deleted
      end
    end

    def delete_prefixed(prefix)
      instrument :delete_prefixed, prefix: prefix do
        ::ActiveStorageDB::File.where('ref LIKE ?', "#{ApplicationRecord.sanitize_sql_like(prefix)}%").destroy_all
      end
    end

    def exist?(key)
      instrument :exist, key: key do |payload|
        answer = ::ActiveStorageDB::File.where(ref: key).exists?
        payload[:exist] = answer
        answer
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
            service_name: respond_to?(:name) ? name : 'db'
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
      { 'Content-Type' => content_type }
    end

    private

    def adapter_sqlserver?
      @adapter_sqlserver ||= ActiveStorageDB::File.connection.adapter_name == 'SQLServer'
    end

    def generate_url(key, expires_in:, filename:, content_type:, disposition:)
      content_disposition = content_disposition_with(type: disposition, filename: filename)
      verified_key_with_expiration = ActiveStorage.verifier.generate(
        {
          key: key,
          disposition: content_disposition,
          content_type: content_type,
          service_name: respond_to?(:name) ? name : 'db'
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

    def ensure_integrity_of(key, checksum)
      return if Digest::MD5.base64digest(object_for(key).data) == checksum

      delete(key)
      raise ActiveStorage::IntegrityError
    end

    def retrieve_file(key)
      file = object_for(key)
      raise(ActiveStorage::FileNotFoundError) unless file

      file.data
    end

    def object_for(key, fields: nil)
      as_file = fields ? ::ActiveStorageDB::File.select(*fields) : ::ActiveStorageDB::File
      as_file.find_by(ref: key)
    end

    def stream(key)
      data_size = adapter_sqlserver? ? 'DATALENGTH(data)' : 'OCTET_LENGTH(data)'
      size = object_for(key, fields: "#{data_size} AS size")&.size || raise(ActiveStorage::FileNotFoundError)
      (size / @chunk_size.to_f).ceil.times.each do |i|
        range = (i * @chunk_size..((i + 1) * @chunk_size) - 1)
        yield download_chunk(key, range)
      end
    end

    def url_helpers
      @url_helpers ||= ::ActiveStorageDB::Engine.routes.url_helpers
    end
  end
end
