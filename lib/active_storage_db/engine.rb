# frozen_string_literal: true

module ActiveStorageDB
  # :nocov:
  UNPROCESSABLE_STATUS = if Rails::VERSION::MAJOR > 7 || (Rails::VERSION::MAJOR == 7 && Rails::VERSION::MINOR >= 1)
                           :unprocessable_content
                         else
                           :unprocessable_entity
                         end
  # :nocov:

  class Engine < ::Rails::Engine
    isolate_namespace ActiveStorageDB

    config.active_storage_db = ActiveSupport::OrderedOptions.new
    config.active_storage_db.service = nil
  end
end
