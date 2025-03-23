# frozen_string_literal: true

class Post < ApplicationRecord
  has_one_attached :some_file do |attachable|
    attachable.variant :thumb, resize_to_limit: [100, 100]
  end

  validates :title, presence: true, allow_blank: false
end
