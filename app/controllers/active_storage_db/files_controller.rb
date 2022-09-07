# frozen_string_literal: true

module ActiveStorageDB
  class FilesController < ActiveStorage::BaseController
    skip_forgery_protection

    def show
      if (key = decode_verified_key)
        serve_file(key[:key], content_type: key[:content_type], disposition: key[:disposition])
      else
        head(:not_found)
      end
    rescue ActiveStorage::FileNotFoundError
      head(:not_found)
    end

    def update
      if (token = decode_verified_token)
        file_uploaded = upload_file(token, body: request.body)
        head(file_uploaded ? :no_content : :unprocessable_entity)
      else
        head(:not_found)
      end
    rescue ActiveStorage::IntegrityError
      head(:unprocessable_entity)
    end

    private

    def acceptable_content?(token)
      token[:content_type] == request.content_mime_type && token[:content_length] == request.content_length
    end

    def db_service
      ActiveStorage::Blob.service
    end

    def decode_verified_key
      key = ActiveStorage.verifier.verified(params[:encoded_key], purpose: :blob_key)
      key&.deep_symbolize_keys
    end

    def decode_verified_token
      token = ActiveStorage.verifier.verified(params[:encoded_token], purpose: :blob_token)
      token&.deep_symbolize_keys
    end

    def serve_file(key, content_type:, disposition:)
      options = {
        type: content_type || DEFAULT_SEND_FILE_TYPE,
        disposition: disposition || DEFAULT_SEND_FILE_DISPOSITION
      }
      send_data(db_service.download(key), options)
    end

    def upload_file(token, body:)
      return false unless acceptable_content?(token)

      db_service.upload(token[:key], request.body, checksum: token[:checksum])
      true
    end
  end
end
