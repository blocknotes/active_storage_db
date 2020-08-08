# frozen_string_literal: true

RSpec.describe ActiveStorage::Service::DBService do
  let(:fixture_data) {
    (+"\211PNG\r\n\032\n\000\000\000\rIHDR\000\000\000\020\000\000\000\020\001\003\000\000\000%=m\"\000\000\000\006PLTE\000\000\000\377\377\377\245\331\237\335\000\000\0003IDATx\234c\370\377\237\341\377_\206\377\237\031\016\2603\334?\314p\1772\303\315\315\f7\215\031\356\024\203\320\275\317\f\367\201R\314\f\017\300\350\377\177\000Q\206\027(\316]\233P\000\000\000\000IEND\256B`\202").force_encoding(Encoding::BINARY) # rubocop:disable Layout/LineLength
  }
  let(:content_type) { 'image/png' }
  let(:checksum) { Digest::MD5.base64digest(fixture_data) }
  let(:key) { SecureRandom.base58(24) }
  let(:tmp_config) { { tmp: { service: 'DB' } } }
  let(:service) { described_class.configure(:tmp, tmp_config) }
  let(:upload_options) { {} }
  let(:upload) { service.upload(key, StringIO.new(fixture_data), upload_options) }

  before do
    allow(ENV).to receive(:fetch).and_call_original
    allow(ENV).to receive(:fetch).with('ASDB_CHUNK_SIZE').and_return(100)
  end

  describe '.delete' do
    before { upload }

    it 'deletes the file' do
      expect(service.delete(key)).to be_kind_of ActiveStorageDB::File
      expect(service.delete(key)).to be_nil
    end
  end

  describe '.delete_prefixed' do
    it 'deletes the files' do
      file = upload
      prefix = key[0..10]
      expect(service.delete_prefixed(prefix)).to eq [file]
      expect(service.delete_prefixed(prefix)).to be_empty
    end
  end

  describe '.download' do
    subject(:download) { service.download(key) }

    it 'raises an exception' do
      expect { download }.to raise_exception ActiveStorage::FileNotFoundError
    end

    context 'with an existing file' do
      before { upload }

      after { service.delete(key) }

      it 'downloads the data' do
        is_expected.to eq fixture_data
      end

      context 'with a block' do
        it 'sends the data to the block' do
          result = nil
          service.download(key) do |data|
            if result
              result += data
            else
              result = data
            end
          end
          expect(result).to eq fixture_data
        end
      end
    end
  end

  describe '.download_chunk' do
    let(:subject) { service.download_chunk(key, range) }
    let(:range) { (10..25) }

    before { upload }

    after { service.delete(key) }

    it 'download a specific chunk of data' do
      is_expected.to eq fixture_data[range]
    end
  end

  describe '.exist?' do
    subject(:exist) { service.exist?(key) }

    it { is_expected.to be_falsey }

    context 'after an upload' do
      before { upload }

      after { service.delete(key) }

      it { is_expected.to be_truthy }
    end
  end

  describe '.headers_for_direct_upload' do
    subject(:headers) { service.headers_for_direct_upload(key, content_type: content_type) }

    it 'returns the headers' do
      is_expected.to eq({ 'Content-Type' => content_type })
    end
  end

  describe '.upload' do
    it 'uploads the data' do
      expect(upload).to be_kind_of ActiveStorageDB::File
    ensure
      service.delete(key)
    end

    context 'with the checksum' do
      let(:upload_options) { { checksum: checksum } }

      it 'uploads the data' do
        expect(upload).to be_kind_of ActiveStorageDB::File
      ensure
        service.delete(key)
      end
    end

    context 'with an invalid checksum' do
      let(:upload_options) { { checksum: Digest::MD5.base64digest('some other data') } }

      it 'fails to upload the data' do
        expect { upload }.to raise_exception ActiveStorage::IntegrityError
      end
    end
  end

  describe '.url' do
    let(:subject) do
      filename = ActiveStorage::Filename.new('avatar.png')
      service.url(key, expires_in: 5.minutes, disposition: :inline, filename: filename, content_type: content_type)
    end
    let(:host) { 'http://test.example.com:3001' }

    before do
      upload
      allow(ActiveStorage::Current).to receive(:host).and_return(host)
    end

    after { service.delete(key) }

    it 'generates the file URL' do
      is_expected.to start_with host
    end
  end

  describe '.url_for_direct_upload' do
    let(:url_options) do
      { expires_in: 5.minutes, content_type: content_type, content_length: fixture_data.size, checksum: checksum }
    end
    let(:subject) { service.url_for_direct_upload(key, url_options) }
    let(:host) { 'http://test.example.com:3001' }

    before do
      upload
      allow(ActiveStorage::Current).to receive(:host).and_return(host)
    end

    after { service.delete(key) }

    it 'generates the file URL' do
      is_expected.to start_with host
    end
  end
end
