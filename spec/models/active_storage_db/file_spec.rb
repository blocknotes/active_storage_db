# frozen_string_literal: true

RSpec.describe ActiveStorageDB::File, type: :model do
  let(:file) { create(:active_storage_db_file, ref: 'just_some_key') }

  context 'when creating a file with an already existing key' do
    before { file }

    it 'raises record invalid exception' do
      expect { create(:active_storage_db_file, ref: 'just_some_key') }.to raise_exception(
        ActiveRecord::RecordInvalid,
        /Ref has already been taken/
      )
    end
  end
end
