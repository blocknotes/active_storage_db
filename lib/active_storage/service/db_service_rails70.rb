# frozen_string_literal: true

module ActiveStorage
  module DBServiceRails70
    private

    def current_host
      opts = url_options || {}
      url = "#{opts[:protocol]}#{opts[:host]}"
      url + ":#{opts[:port]}" if opts[:port]
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
