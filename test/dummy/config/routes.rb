Rails.application.routes.draw do
  mount ActiveStorageDB::Engine => "/active_storage_db"
end
