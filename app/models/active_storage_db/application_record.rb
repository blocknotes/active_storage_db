# frozen_string_literal: true

module ActiveStorageDB
  class ApplicationRecord < ActiveRecord::Base
    self.abstract_class = true
  end
end
