# frozen_string_literal: true

module ActiveStorage
  # Wraps a DB table as an Active Storage service. See ActiveStorage::Service
  # for the generic API documentation that applies to all services.
  class Service::DBService < Service
    def initialize(**)
      @chunk_size = ENV.fetch('ASDB_CHUNK_SIZE') { 1.megabytes }
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
          record = ::ActiveStorageDB::File.find_by(ref: key)
          raise(ActiveStorage::FileNotFoundError) unless record

          record.data
        end
      end
    end

    def download_chunk(key, range)
      instrument :download_chunk, key: key, range: range do
        chunk_select = "SUBSTRING(data FROM #{range.begin + 1} FOR #{range.size}) AS chunk"
        record = ::ActiveStorageDB::File.select(chunk_select).find_by(ref: key)
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
        ::ActiveStorageDB::File.where('ref LIKE ?', "#{prefix}%").destroy_all
      end
    end

    def exist?(key)
      instrument :exist, key: key do |payload|
        answer = ::ActiveStorageDB::File.where(ref: key).exists?
        payload[:exist] = answer
        answer
      end
    end

    if Rails::VERSION::MAJOR == 6 && Rails::VERSION::MINOR == 0
      def url(key, expires_in:, filename:, disposition:, content_type:)
        instrument :url, key: key do |payload|
          opts = { expires_in: expires_in, filename: filename, content_type: content_type, disposition: disposition }
          generate_url(key, opts).tap do |generated_url|
            payload[:url] = generated_url
          end
        end
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

    def current_host
      if ActiveStorage::Current.respond_to? :url_options
        opts = ActiveStorage::Current.url_options || {}
        url = "#{opts[:protocol]}#{opts[:host]}"
        url += ":#{opts[:port]}" if opts[:port]
        url || ''
      else
        ActiveStorage::Current.host
      end
    end

    def private_url(key, expires_in:, filename:, content_type:, disposition:, **)
      generate_url(key, expires_in: expires_in, filename: filename, content_type: content_type, disposition: disposition)
    end

    def public_url(key, filename:, content_type: nil, disposition: :attachment, **)
      generate_url(key, expires_in: nil, filename: filename, content_type: content_type, disposition: disposition)
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
      file = ::ActiveStorageDB::File.find_by(ref: key)
      return if Digest::MD5.base64digest(file.data) == checksum

      delete(key)
      raise ActiveStorage::IntegrityError
    end

    def stream(key)
      size =
        ::ActiveStorageDB::File.select('OCTET_LENGTH(data) AS size').find_by(ref: key)&.size ||
        raise(ActiveStorage::FileNotFoundError)
      (size / @chunk_size.to_f).ceil.times.each do |i|
        range = (i * @chunk_size..((i + 1) * @chunk_size) - 1)
        yield download_chunk(key, range)
      end
    end

    def url_helpers
      @url_helpers ||= ::ActiveStorageDB::Engine.routes.url_helpers
    end

    def url_options
      if ActiveStorage::Current.respond_to? :url_options
        ActiveStorage::Current.url_options
      else
        { host: ActiveStorage::Current.host }
      end
    end
  end
end
