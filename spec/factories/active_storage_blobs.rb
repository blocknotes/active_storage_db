# frozen_string_literal: true

FactoryBot.define do
  factory :active_storage_blob, class: 'ActiveStorage::Blob' do
    sequence(:filename) { |n| "file_#{n}" }
    byte_size { 1234 }
    checksum { 'some_checksum' }
    created_at { Time.now }
  end
end
