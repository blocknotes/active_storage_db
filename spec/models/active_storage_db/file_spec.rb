# frozen_string_literal: true

RSpec.describe ActiveStorageDB::File do
  describe "validations" do
    context "when ref is nil" do
      it "raises record invalid exception" do
        expect { create(:active_storage_db_file, ref: nil) }.to raise_exception(
          ActiveRecord::RecordInvalid,
          /Ref can't be blank/
        )
      end
    end

    context "when ref is blank" do
      it "raises record invalid exception" do
        expect { create(:active_storage_db_file, ref: "") }.to raise_exception(
          ActiveRecord::RecordInvalid,
          /Ref can't be blank/
        )
      end
    end

    context "when creating a file with an already existing key" do
      before { create(:active_storage_db_file, ref: "just_some_key") }

      it "raises record invalid exception" do
        expect { create(:active_storage_db_file, ref: "just_some_key") }.to raise_exception(
          ActiveRecord::RecordInvalid,
          /Ref has already been taken/
        )
      end
    end

    context "when ref uniqueness is case-insensitive" do
      before { create(:active_storage_db_file, ref: "Some_Key") }

      it "rejects a key differing only in case" do
        expect { create(:active_storage_db_file, ref: "some_key") }.to raise_exception(
          ActiveRecord::RecordInvalid,
          /Ref has already been taken/
        )
      end
    end
  end

  describe "CRUD lifecycle" do
    let(:file) { create(:active_storage_db_file, ref: "lifecycle_key") }

    it "persists and retrieves binary data", :aggregate_failures do
      reloaded = described_class.find(file.id)
      expect(reloaded.data).to eq file.data
      expect(reloaded.ref).to eq "lifecycle_key"
    end

    it "updates data" do
      file.update!(data: "new content")
      expect(file.reload.data).to eq "new content"
    end

    it "destroys the record" do
      file
      expect { file.destroy! }.to change(described_class, :count).by(-1)
    end
  end
end
