# frozen_string_literal: true

ActiveStorageDB::Engine.routes.draw do
  get '/files/:encoded_key/*filename', to: 'files#show', as: :service
  put '/files/:encoded_token', to: 'files#update', as: :update_service
end
