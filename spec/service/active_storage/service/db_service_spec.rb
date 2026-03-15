# frozen_string_literal: true

RSpec.describe ActiveStorage::Service::DBService do
  let(:fixture_data) { build(:active_storage_db_file).data }
  let(:content_type) { "image/png" }
  let(:url_options) do
    {
      protocol: "http://",
      host: "test.example.com",
      port: "3001"
    }
  end
  let(:host) { "#{url_options[:protocol]}#{url_options[:host]}:#{url_options[:port]}" }

  let(:checksum) { Digest::MD5.base64digest(fixture_data) }
  let(:key) { SecureRandom.base58(24) }
  let(:service) { described_class.configure(:tmp, tmp: { service: "DB" }) }
  let(:upload) { service.upload(key, StringIO.new(fixture_data)) }

  before do
    allow(ENV).to receive(:fetch).and_call_original
    allow(ENV).to receive(:fetch).with("ASDB_CHUNK_SIZE").and_return("100")
  end

  describe "public URL generation" do
    let(:config) do
      {
        db: {
          service: "db",
          public: true
        }
      }
    end

    before do
      if ActiveStorage::Current.respond_to? :url_options
        allow(ActiveStorage::Current).to receive(:url_options).and_return(url_options)
      else
        allow(ActiveStorage::Current).to receive(:host).and_return(host)
      end
    end

    it "returns a public URL" do
      filename = ActiveStorage::Filename.new("some_filename")
      service = ActiveStorage::Service.configure(:db, config)
      url = service.url("some_key", filename: filename, disposition: :inline, content_type: "text/plain", expires_in: nil)
      expect(url).to match %r{#{host}/active_storage_db/files/}
    end

    context "without port" do
      let(:url_options) do
        {
          protocol: "https://",
          host: "test.example.com"
        }
      end

      it "returns a public URL" do
        filename = ActiveStorage::Filename.new("some_filename")
        service = ActiveStorage::Service.configure(:db, config)
        url = service.url("some_key", filename: filename, disposition: :inline, content_type: "text/plain", expires_in: nil)
        expect(url).to match %r{https://test.example.com/active_storage_db/files/}
      end
    end
  end

  if Rails::VERSION::MAJOR >= 7
    describe ".compose" do
      subject(:compose) { service.compose(%w[key1 key2 key3], "dest_key") }

      let!(:first_db_file) { create(:active_storage_db_file, ref: "key1", data: "first file") }
      let!(:second_db_file) { create(:active_storage_db_file, ref: "key2", data: "second file") }
      let!(:third_db_file) { create(:active_storage_db_file, ref: "key3", data: "third file") }

      it "composes the source files", :aggregate_failures do
        expect { compose }.to change { ActiveStorageDB::File.where(ref: "dest_key").count }.by(1)
        expect(compose).to be_a ActiveStorageDB::File
        expect(compose.data).to eq [first_db_file.data, second_db_file.data, third_db_file.data].join
      end

      context "when a source key is missing" do
        subject(:compose) { service.compose(%w[key1 missing_key key3], "dest_key") }

        it "raises FileNotFoundError" do
          expect { compose }.to raise_exception(ActiveStorage::FileNotFoundError)
        end

        it "does not create the destination file" do
          compose rescue nil # rubocop:disable Style/RescueModifier
          expect(ActiveStorageDB::File.find_by(ref: "dest_key")).to be_nil
        end
      end

      context "with empty source keys" do
        subject(:compose) { service.compose([], "dest_key") }

        it "does not create a destination file" do
          expect { compose }.not_to change(ActiveStorageDB::File, :count)
        end

        it "returns nil" do
          expect(compose).to be_nil
        end
      end
    end
  end

  describe ".delete" do
    subject(:delete) { service.delete(key) }

    before { upload }

    it { is_expected.to be_truthy }

    it "deletes the file" do
      expect { delete }.to change(ActiveStorageDB::File, :count).from(1).to(0)
    end

    context "when the attachment is not found" do
      subject(:delete) { service.delete("#{key}!") }

      it { is_expected.to be_falsey }
    end
  end

  describe ".delete_prefixed" do
    subject(:delete_prefixed) { service.delete_prefixed(key[0..10]) }

    before { upload }

    it "deletes the files" do
      expect { delete_prefixed }.to change(ActiveStorageDB::File, :count).from(1).to(0)
    end

    context "when no files match the prefix" do
      subject(:delete_prefixed) { service.delete_prefixed("nonexistent_prefix") }

      it "does not raise and deletes nothing" do
        expect { delete_prefixed }.not_to change(ActiveStorageDB::File, :count)
      end
    end
  end

  describe ".download" do
    subject(:download) { service.download(key) }

    it "raises an exception" do
      expect { download }.to raise_exception ActiveStorage::FileNotFoundError
    end

    context "with an existing file" do
      before { upload }

      after { service.delete(key) }

      it "downloads the data" do
        expect(download).to eq fixture_data
      end

      context "when a block is provided" do
        it "sends the data to the block" do
          result = +""
          service.download(key) { |chunk| result << chunk }
          expect(result).to eq fixture_data
        end

        it "yields multiple chunks when data exceeds chunk size", :aggregate_failures do
          chunks = []
          service.download(key) { |chunk| chunks << chunk }
          # fixture_data is a PNG (~100 bytes), chunk size is 100 bytes,
          # so we expect at least 1 chunk yielded via the streaming path
          expect(chunks).not_to be_empty
          expect(chunks.join).to eq fixture_data
        end
      end

      context "with download a block and when the attachment is not found" do
        let(:download_block) do
          service.download("#{key}!") do |_data| # rubocop:disable Lint/EmptyBlock
          end
        end

        it { expect { download_block }.to raise_exception(ActiveStorage::FileNotFoundError) }
      end
    end
  end

  describe ".download_chunk" do
    subject { service.download_chunk(key, range) }

    let(:range) { (10..15) }

    before { upload }

    after { service.delete(key) }

    it { is_expected.to eq fixture_data[range] }

    context "when the attachment is not found" do
      subject(:download_chunk) { service.download_chunk("#{key}!", range) }

      it { expect { download_chunk }.to raise_exception(ActiveStorage::FileNotFoundError) }
    end
  end

  describe ".exist?" do
    subject { service.exist?(key) }

    it { is_expected.to be_falsey }

    context "when a file is uploaded" do
      before { upload }

      after { service.delete(key) }

      it { is_expected.to be_truthy }
    end
  end

  describe ".headers_for_direct_upload" do
    subject { service.headers_for_direct_upload(key, content_type: content_type) }

    it { is_expected.to eq("Content-Type" => content_type) }
  end

  describe ".upload" do
    it "uploads the data" do
      expect(upload).to be_a ActiveStorageDB::File
    ensure
      service.delete(key)
    end

    context "with the checksum" do
      let(:upload) { service.upload(key, StringIO.new(fixture_data), checksum: checksum) }

      it "uploads the data" do
        expect(upload).to be_a ActiveStorageDB::File
      ensure
        service.delete(key)
      end
    end

    context "with an invalid checksum" do
      let(:checksum) { Digest::MD5.base64digest("some other data") }
      let(:upload) { service.upload(key, StringIO.new(fixture_data), checksum: checksum) }

      it "fails to upload the data" do
        expect { upload }.to raise_exception ActiveStorage::IntegrityError
      end

      it "does not persist the file" do
        expect { upload rescue nil }.not_to change(ActiveStorageDB::File, :count) # rubocop:disable Style/RescueModifier
      end
    end

    context "with a duplicate key" do
      before { upload }

      after { service.delete(key) }

      it "raises a uniqueness error" do
        expect {
          service.upload(key, StringIO.new(fixture_data))
        }.to raise_exception(ActiveRecord::RecordInvalid, /Ref has already been taken/)
      end
    end
  end

  describe ".url_for_direct_upload" do
    subject(:url_for_direct_upload) do
      service.url_for_direct_upload(
        key,
        expires_in: 5.minutes,
        content_type: content_type,
        content_length: fixture_data.size,
        checksum: checksum
      )
    end

    before do
      upload
      if ActiveStorage::Current.respond_to? :url_options
        allow(ActiveStorage::Current).to receive(:url_options).and_return(url_options)
      else
        allow(ActiveStorage::Current).to receive(:host).and_return(host)
      end
    end

    after { service.delete(key) }

    it { is_expected.to start_with "#{url_options[:protocol]}#{url_options[:host]}" }

    it "generates a token that contains the expected fields" do
      url = url_for_direct_upload
      token = url.split("/").last
      verified = ActiveStorage.verifier.verified(token, purpose: :blob_token).symbolize_keys
      expect(verified).to include(
        key: key,
        content_type: content_type,
        content_length: fixture_data.size,
        checksum: checksum
      )
      expect(verified[:service_name]).to be_present
    end
  end

  describe "service_name_for_token" do
    it "returns the service name when set" do
      service.name = "custom_db"
      expect(service.send(:service_name_for_token)).to eq("custom_db")
    end

    it "falls back to 'db' when name is nil" do
      service.name = nil
      expect(service.send(:service_name_for_token)).to eq("db")
    end
  end

  describe "chunk_size validation" do
    it "enforces a minimum chunk size of 1" do
      allow(ENV).to receive(:fetch).with("ASDB_CHUNK_SIZE").and_return("0")
      svc = described_class.configure(:tmp, tmp: { service: "DB" })
      expect(svc.instance_variable_get(:@chunk_size)).to eq(1)
    end

    it "enforces a minimum chunk size for negative values" do
      allow(ENV).to receive(:fetch).with("ASDB_CHUNK_SIZE").and_return("-5")
      svc = described_class.configure(:tmp, tmp: { service: "DB" })
      expect(svc.instance_variable_get(:@chunk_size)).to eq(1)
    end
  end
end
