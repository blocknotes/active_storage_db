# frozen_string_literal: true

module BlobHelpers
  def create_blob(data: "Hello world!", filename: "hello.txt", content_type: "text/plain", identify: true, record: nil)
    ActiveStorage::Blob.create_and_upload!(
      io: StringIO.new(data),
      filename: filename,
      content_type: content_type,
      identify: identify,
      record: record
    )
  end

  def create_blob_before_direct_upload(byte_size:, checksum:, filename: "hello.txt", content_type: "text/plain")
    ActiveStorage::Blob.create_before_direct_upload!(
      filename: filename,
      byte_size: byte_size,
      checksum: checksum,
      content_type: content_type
    )
  end
end

RSpec.configure do |config|
  config.include BlobHelpers
end
