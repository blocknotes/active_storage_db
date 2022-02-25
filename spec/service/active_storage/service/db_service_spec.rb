# frozen_string_literal: true

RSpec.describe ActiveStorage::Service::DBService do
  let(:fixture_data) { build(:active_storage_db_file).data }
  let(:content_type) { 'image/png' }
  let(:url_options) do
    {
      protocol: 'http://',
      host: 'test.example.com',
      port: '3001',
    }
  end
  let(:host) { "#{url_options[:protocol]}#{url_options[:host]}:#{url_options[:port]}" }

  let(:checksum) { Digest::MD5.base64digest(fixture_data) }
  let(:key) { SecureRandom.base58(24) }
  let(:service) { described_class.configure(:tmp, tmp: { service: 'DB' }) }
  let(:upload) { service.upload(key, StringIO.new(fixture_data)) }

  before do
    allow(ENV).to receive(:fetch).and_call_original
    allow(ENV).to receive(:fetch).with('ASDB_CHUNK_SIZE').and_return(100)
  end

  describe 'public URL generation' do
    let(:config) do
      {
        db: {
          service: 'db',
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

    it 'returns a public URL' do
      filename = ActiveStorage::Filename.new('some_filename')
      service = ActiveStorage::Service.configure(:db, config)
      url = service.url('some_key', filename: filename, disposition: :inline, content_type: 'text/plain', expires_in: nil)
      expect(url).to match %r{#{host}/active_storage_db/files/}
    end
  end

  describe '.delete' do
    subject(:delete) { service.delete(key) }

    before { upload }

    it 'deletes the file' do
      expect { delete }.to change { ActiveStorageDB::File.count }.from(1).to(0)
    end
  end

  describe '.delete_prefixed' do
    subject(:delete_prefixed) { service.delete_prefixed(key[0..10]) }

    before { upload }

    it 'deletes the files' do
      expect { delete_prefixed }.to change { ActiveStorageDB::File.count }.from(1).to(0)
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
        expect(download).to eq fixture_data
      end

      context 'with download a block' do
        let(:download_block) do
          result = nil
          service.download(key) do |data|
            if result
              result += data
            else
              result = data
            end
          end
          result
        end

        it 'sends the data to the block' do
          expect(download_block).to eq fixture_data
        end
      end
    end
  end

  describe '.download_chunk' do
    subject { service.download_chunk(key, range) }

    let(:range) { (10..15) }

    before { upload }

    after { service.delete(key) }

    it { is_expected.to eq fixture_data[range] }
  end

  describe '.exist?' do
    subject { service.exist?(key) }

    it { is_expected.to be_falsey }

    context 'when a file is uploaded' do
      before { upload }

      after { service.delete(key) }

      it { is_expected.to be_truthy }
    end
  end

  describe '.headers_for_direct_upload' do
    subject { service.headers_for_direct_upload(key, content_type: content_type) }

    it { is_expected.to eq('Content-Type' => content_type) }
  end

  describe '.upload' do
    it 'uploads the data' do
      expect(upload).to be_kind_of ActiveStorageDB::File
    ensure
      service.delete(key)
    end

    context 'with the checksum' do
      let(:upload) { service.upload(key, StringIO.new(fixture_data), checksum: checksum) }

      it 'uploads the data' do
        expect(upload).to be_kind_of ActiveStorageDB::File
      ensure
        service.delete(key)
      end
    end

    context 'with an invalid checksum' do
      let(:checksum) { Digest::MD5.base64digest('some other data') }
      let(:upload) { service.upload(key, StringIO.new(fixture_data), checksum: checksum) }

      it 'fails to upload the data' do
        expect { upload }.to raise_exception ActiveStorage::IntegrityError
      end
    end
  end

  describe '.url_for_direct_upload' do
    subject do
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
  end
end
