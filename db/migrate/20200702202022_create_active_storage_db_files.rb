# frozen_string_literal: true

class CreateActiveStorageDBFiles < ActiveRecord::Migration[6.0]
  def change
    create_table :active_storage_db_files, id: primary_key_type do |t|
      t.string :ref, null: false
      t.binary :data, null: false

      if connection.supports_datetime_with_precision?
        t.datetime :created_at, precision: 6, null: false
      else
        t.datetime :created_at, null: false
      end

      t.index [:ref], unique: true
      t.index [:created_at]
    end

    add_index :active_storage_db_files, [:ref, :created_at],
              name: "index_active_storage_db_files_ref_created",
              order: { created_at: :desc }
  end

  private

  def primary_key_type
    config = Rails.configuration.generators
    config.options.dig(config.orm, :primary_key_type) || :primary_key
  end
end
