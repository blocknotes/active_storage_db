# frozen_string_literal: true

module ActiveStorage
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
          record&.data || raise(ActiveStorage::FileNotFoundError)
        end
      end
    end

    def download_chunk(key, range)
      instrument :download_chunk, key: key, range: range do
        chunk_select = "SUBSTRING(data FROM #{range.begin + 1} FOR #{range.size}) AS chunk"
        ::ActiveStorageDB::File.select(chunk_select).find_by(ref: key)&.chunk ||
          raise(ActiveStorage::FileNotFoundError)
      end
    end

    def delete(key)
      instrument :delete, key: key do
        ::ActiveStorageDB::File.find_by(ref: key)&.destroy
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

    def url(key, expires_in:, filename:, disposition:, content_type:)
      instrument :url, key: key do |payload|
        content_disposition = content_disposition_with(type: disposition, filename: filename)
        verified_key_with_expiration = ActiveStorage.verifier.generate(
          {
            key: key,
            disposition: content_disposition,
            content_type: content_type
          },
          expires_in: expires_in,
          purpose: :blob_key
        )
        current_uri = URI.parse(current_host)
        generated_url = url_helpers.service_url(
          verified_key_with_expiration,
          protocol: current_uri.scheme,
          host: current_uri.host,
          port: current_uri.port,
          disposition: content_disposition,
          content_type: content_type,
          filename: filename
        )
        payload[:url] = generated_url

        generated_url
      end
    end

    def url_for_direct_upload(key, expires_in:, content_type:, content_length:, checksum:, custom_metadata: {})
      instrument :url, key: key do |payload|
        verified_token_with_expiration = ActiveStorage.verifier.generate(
          {
            key: key,
            content_type: content_type,
            content_length: content_length,
            checksum: checksum
          },
          expires_in: expires_in,
          purpose: :blob_token
        )
        generated_url = url_helpers.update_service_url(verified_token_with_expiration, host: current_host)
        payload[:url] = generated_url

        generated_url
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
  end
end
