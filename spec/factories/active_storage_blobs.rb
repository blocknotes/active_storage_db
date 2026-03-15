# frozen_string_literal: true

FactoryBot.define do
  factory :active_storage_blob, class: "ActiveStorage::Blob" do
    sequence(:filename) { |n| "file_#{n}" }
    byte_size { 1234 }
    checksum { Digest::MD5.base64digest("factory_blob_data") }
    service_name { "db" }
    created_at { Time.current }
  end
end
