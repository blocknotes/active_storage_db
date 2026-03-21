# frozen_string_literal: true

module ActiveStorageDB
  class File < ApplicationRecord
    validates :ref, presence: true, uniqueness: true
    validates :data, presence: true
  end
end
