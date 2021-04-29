# frozen_string_literal: true

namespace :asdb do
  desc 'ActiveStorageDB: list attachments'
  task list: [:environment] do |_t, _args|
    ::ActiveStorage::Blob.order(:filename).pluck(:byte_size, :created_at, :filename).each do |size, dt, filename|
      size_k = (size / 1024).to_s.rjust(7)
      date = dt.strftime('%Y-%m-%d %H:%M')
      puts "#{size_k}K  #{date}  #{filename}"
    end
  end

  desc 'ActiveStorageDB: download attachment'
  task :get, [:src, :dst] => [:environment] do |_t, args|
    src = args[:src]&.strip
    dst = args[:dst]&.strip
    abort('Required arguments: source file, destination file') if src.blank? || dst.blank?

    dst = "#{dst}/#{src}" if Dir.exist?(dst)
    dir = File.dirname(dst)
    abort("Can't write on: #{dir}") unless File.writable?(dir)

    blob = ::ActiveStorage::Blob.order(created_at: :desc).find_by(filename: src)
    abort('Source file not found') unless blob

    ret = File.binwrite(dst, blob.download)
    puts "#{ret} bytes written"
  rescue StandardError => e
    puts e
  end
end
