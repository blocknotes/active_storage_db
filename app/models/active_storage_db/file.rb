# frozen_string_literal: true

module ActiveStorageDB
  class File < ApplicationRecord
    validates :ref,
              presence: true,
              allow_blank: false,
              uniqueness: { case_sensitive: false }
  end
end
