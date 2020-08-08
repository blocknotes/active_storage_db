# frozen_string_literal: true

module ActiveStorageDB
  class FilesController < ActiveStorage::BaseController
    skip_forgery_protection

    def show
      if (key = decode_verified_key)
        serve_file(key[:key], content_type: key[:content_type], disposition: key[:disposition])
      else
        head :not_found
      end
    rescue ActiveStorage::FileNotFoundError
      head :not_found
    end

    def update
      if (token = decode_verified_token)
        if acceptable_content?(token)
          db_service.upload(token[:key], request.body, checksum: token[:checksum])
        else
          head :unprocessable_entity
        end
      else
        head :not_found
      end
    rescue ActiveStorage::IntegrityError
      head :unprocessable_entity
    end

    private

    def db_service
      ActiveStorage::Blob.service
    end

    def decode_verified_key
      ActiveStorage.verifier.verified(params[:encoded_key], purpose: :blob_key)
    end

    def serve_file(key, content_type:, disposition:)
      options = {
        type: content_type || DEFAULT_SEND_FILE_TYPE,
        disposition: disposition || DEFAULT_SEND_FILE_DISPOSITION
      }
      send_data db_service.download(key), options
    end

    def decode_verified_token
      ActiveStorage.verifier.verified(params[:encoded_token], purpose: :blob_token)
    end

    def acceptable_content?(token)
      token[:content_type] == request.content_mime_type && token[:content_length] == request.content_length
    end
  end
end
