# frozen_string_literal: true

module ActiveStorageDB
  class FilesController < ActiveStorage::BaseController
    skip_forgery_protection

    def show
      if (key = decode_verified_key)
        attrs = key.slice(:content_type, :disposition, :service_name)
        serve_file(key[:key], **attrs)
      else
        head(:not_found)
      end
    rescue ActiveStorage::FileNotFoundError
      head(:not_found)
    end

    def update
      if (token = decode_verified_token)
        file_uploaded = upload_file(token)
        head(file_uploaded ? :no_content : ActiveStorageDB::UNPROCESSABLE_STATUS)
      else
        head(:not_found)
      end
    rescue ActiveStorage::IntegrityError
      head(ActiveStorageDB::UNPROCESSABLE_STATUS)
    end

    private

    def acceptable_content?(token)
      token[:content_type] == request.media_type &&
        token[:content_length] == request.content_length
    end

    def db_service_for(service_name)
      if service_name && ActiveStorage::Blob.respond_to?(:services)
        ActiveStorage::Blob.services.fetch(service_name) { ActiveStorage::Blob.service }
      else
        ActiveStorage::Blob.service
      end
    end

    def decode_verified_key
      key = ActiveStorage.verifier.verified(params[:encoded_key], purpose: :blob_key)
      key&.deep_symbolize_keys
    end

    def decode_verified_token
      token = ActiveStorage.verifier.verified(params[:encoded_token], purpose: :blob_token)
      token&.deep_symbolize_keys
    end

    def serve_file(key, content_type:, disposition:, service_name: nil)
      options = {
        type: content_type || DEFAULT_SEND_FILE_TYPE,
        disposition: disposition || DEFAULT_SEND_FILE_DISPOSITION
      }
      send_data(db_service_for(service_name).download(key), options)
    end

    def upload_file(token) # rubocop:disable Naming/PredicateMethod
      return false unless acceptable_content?(token)

      service = db_service_for(token[:service_name])
      service.upload(token[:key], request.body, checksum: token[:checksum])
      true
    end
  end
end
