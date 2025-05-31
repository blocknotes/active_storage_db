# frozen_string_literal: true

module ActiveStorage
  module DBServiceRails70
    def compose(source_keys, destination_key, **)
      buffer = nil
      comment = "DBService#compose"
      source_keys.each do |source_key|
        data = ::ActiveStorageDB::File.annotate(comment).find_by!(ref: source_key).data
        if buffer
          buffer << data
        else
          buffer = +data
        end
      end
      ::ActiveStorageDB::File.create!(ref: destination_key, data: buffer) if buffer
    end

    private

    def current_host
      opts = url_options || {}
      opts[:port] ? "#{opts[:protocol]}#{opts[:host]}:#{opts[:port]}" : "#{opts[:protocol]}#{opts[:host]}"
    end

    def private_url(key, expires_in:, filename:, content_type:, disposition:, **)
      generate_url(
        key,
        expires_in: expires_in,
        filename: filename,
        content_type: content_type,
        disposition: disposition
      )
    end

    def public_url(key, filename:, content_type: nil, disposition: :attachment, **)
      generate_url(
        key,
        expires_in: nil,
        filename: filename,
        content_type: content_type,
        disposition: disposition
      )
    end

    def url_options
      ActiveStorage::Current.url_options
    end
  end
end
