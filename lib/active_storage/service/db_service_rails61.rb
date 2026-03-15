# frozen_string_literal: true

module ActiveStorage
  module DBServiceRails61
    private

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

    def url_params
      uri = URI.parse(ActiveStorage::Current.host)
      { protocol: uri.scheme, host: uri.host, port: uri.port }
    end
  end
end
