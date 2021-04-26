# frozen_string_literal: true

namespace :asdb do
  desc 'ActiveStorageDB: list attachments'
  task ls: [:environment] do |_t, _args|
    ::ActiveStorage::Blob.order(:filename).pluck(:byte_size, :created_at, :filename).each do |size, dt, filename|
      size_k = (size / 1024).to_s.rjust(7)
      date = dt.strftime('%Y-%m-%d %H:%M')
      puts "#{size_k}K  #{date}  #{filename}"
    end
  end
end
