# frozen_string_literal: true

module ActiveStorage
  module DBServiceRails70
    def compose(source_keys, destination_key, **)
      if source_keys.length > 10 || ENV["ASDB_COMPOSE_USE_TEMP_FILE"] == "true"
        compose_with_temp_file(source_keys, destination_key)
      else
        compose_in_memory(source_keys, destination_key)
      end
    end

    private

    def compose_in_memory(source_keys, destination_key)
      buffer = nil
      comment = "DBService#compose"
      source_keys.each do |source_key|
        record = ::ActiveStorageDB::File.annotate(comment).select(:data).find_by(ref: source_key)
        raise ActiveStorage::FileNotFoundError unless record

        if buffer
          buffer << record.data
        else
          buffer = +record.data
        end
      end
      ::ActiveStorageDB::File.create!(ref: destination_key, data: buffer) if buffer
    end

    def compose_with_temp_file(source_keys, destination_key)
      Tempfile.create(["active_storage_db_compose", ".bin"], binmode: true) do |tempfile|
        comment = "DBService#compose"
        source_keys.each do |source_key|
          record = ::ActiveStorageDB::File.annotate(comment).find_by(ref: source_key)
          raise ActiveStorage::FileNotFoundError unless record

          tempfile.write(record.data)
        end
        tempfile.rewind

        retry_on_failure do
          ::ActiveStorageDB::File.create!(ref: destination_key, data: tempfile.read)
        end
      end
    end
  end
end
