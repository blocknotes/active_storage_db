# frozen_string_literal: true

class CreateActiveStorageDBFiles < ActiveRecord::Migration[6.0]
  def change
    create_table :active_storage_db_files do |t|
      t.string :ref, null: false
      t.binary :data, null: false
      t.datetime :created_at, null: false

      t.index [:ref], unique: true
    end
  end
end
