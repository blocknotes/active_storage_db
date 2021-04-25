# frozen_string_literal: true

FactoryBot.define do
  factory :active_storage_db_file, class: 'ActiveStorageDB::File' do
    ref { ('a'..'z').to_a.shuffle[0, 32].join } # rubocop:disable Style/Sample

    data do
      (+"\211PNG\r\n\032\n\000\000\000\rIHDR\000\000\000\020\000\000\000\020\001\003\000\000\000%=m\"\000\000\000\006PLTE\000\000\000\377\377\377\245\331\237\335\000\000\0003IDATx\234c\370\377\237\341\377_\206\377\237\031\016\2603\334?\314p\1772\303\315\315\f7\215\031\356\024\203\320\275\317\f\367\201R\314\f\017\300\350\377\177\000Q\206\027(\316]\233P\000\000\000\000IEND\256B`\202").force_encoding(Encoding::BINARY) # rubocop:disable Layout/LineLength
    end
  end
end
