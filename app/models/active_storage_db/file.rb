# frozen_string_literal: true

module ActiveStorageDB
  class File < ApplicationRecord
    validates :ref,
              presence: true,
              uniqueness: { case_sensitive: false }
    validates :data, presence: true
  end
end
