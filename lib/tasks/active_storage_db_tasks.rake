# frozen_string_literal: true

module ActiveStorage
  module Tasks
    module_function

    def print_blob_header(digits: 0)
      puts ['Size'.rjust(8), 'Date'.rjust(18), 'Id'.rjust(digits + 2), '  Filename'].join
    end

    def print_blob(blob, digits: 0)
      size = (blob.byte_size / 1024).to_s.rjust(7)
      date = blob.created_at.strftime('%Y-%m-%d %H:%M')
      puts "#{size}K  #{date}  #{blob.id.to_s.rjust(digits)}  #{blob.filename}"
    end
  end
end

namespace :asdb do
  desc 'ActiveStorageDB: list attachments ordered by blob id desc'
  task list: [:environment] do |_t, _args|
    query = ActiveStorage::Blob.order(id: :desc).limit(100)
    digits = query.ids.inject(0) { |ret, id| size = id.to_s.size; [size, ret].max }

    ActiveStorage::Tasks.print_blob_header(digits: digits)
    query.each do |blob|
      ActiveStorage::Tasks.print_blob(blob, digits: digits)
    end
  end

  desc 'ActiveStorageDB: download attachment by blob id'
  task :download, [:blob_id, :destination] => [:environment] do |_t, args|
    blob_id = args[:blob_id]&.strip
    destination = args[:destination]&.strip || Dir.pwd
    abort('Required arguments: source blob id, destination path') if blob_id.blank? || destination.blank?

    blob = ActiveStorage::Blob.find_by(id: blob_id)
    abort('Source file not found') unless blob

    destination = "#{destination}/#{blob.filename}" if Dir.exist?(destination)
    dir = File.dirname(destination)
    abort("Can't write on path: #{dir}") unless File.writable?(dir)

    ret = File.binwrite(destination, blob.download)
    puts "#{ret} bytes written - #{destination}"
  end

  desc 'ActiveStorageDB: search attachment by filename (or part of it)'
  task :search, [:filename] => [:environment] do |_t, args|
    filename = args[:filename]&.strip
    abort('Required arguments: filename') if filename.blank?

    blobs = ActiveStorage::Blob.where('filename LIKE ?', "%#{filename}%").order(id: :desc)
    if blobs.any?
      digits = blobs.ids.inject(0) { |ret, id| size = id.to_s.size; [size, ret].max }
      ActiveStorage::Tasks.print_blob_header(digits: digits)
      blobs.each do |blob|
        ActiveStorage::Tasks.print_blob(blob, digits: digits)
      end
    else
      puts 'No results'
    end
  end
end
