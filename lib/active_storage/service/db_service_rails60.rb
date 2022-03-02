# frozen_string_literal: true

module ActiveStorage
  module DBServiceRails60
    def url(key, expires_in:, filename:, disposition:, content_type:)
      instrument :url, key: key do |payload|
        generate_url(key, expires_in: expires_in, filename: filename, content_type: content_type, disposition: disposition).tap do |generated_url|
          payload[:url] = generated_url
        end
      end
    end

    private

    def current_host
      url_options[:host]
    end

    def url_options
      {
        host: ActiveStorage::Current.host
      }
    end
  end
end
