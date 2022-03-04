# frozen_string_literal: true

class Post < ApplicationRecord
  has_one_attached :some_file

  validates :title, presence: true, allow_blank: false
end
