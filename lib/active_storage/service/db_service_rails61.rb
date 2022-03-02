# frozen_string_literal: true

module ActiveStorage
  module DBServiceRails61
    private

    def current_host
      url_options[:host]
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
      {
        host: ActiveStorage::Current.host
      }
    end
  end
end
