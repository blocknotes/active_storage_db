# frozen_string_literal: true

Rails.application.routes.draw do
  mount ActiveStorageDB::Engine => '/active_storage_db'

  resources :posts

  root 'posts#index'
end
