# frozen_string_literal: true

RSpec.describe 'File controller', type: :request do
  def create_blob(data: 'Hello world!', filename: 'hello.txt', content_type: 'text/plain', identify: true, record: nil)
    ActiveStorage::Blob.create_and_upload! io: StringIO.new(data), filename: filename, content_type: content_type, identify: identify, record: record # rubocop:disable Layout/LineLength
  end

  def create_blob_before_direct_upload(filename: 'hello.txt', byte_size:, checksum:, content_type: 'text/plain')
    ActiveStorage::Blob.create_before_direct_upload! filename: filename, byte_size: byte_size, checksum: checksum, content_type: content_type # rubocop:disable Layout/LineLength
  end

  let(:blob) { create_blob(filename: 'hello.jpg', content_type: 'image/jpg') }
  let(:host) { 'http://test.example.com:3001' }

  before { allow(ActiveStorage::Current).to receive(:host).and_return(host) }

  describe '.show' do
    it 'returns the blob as inline' do
      get blob.service_url

      expect(response).to have_http_status(:ok)
      expect(response.content_type).to eq('image/jpg')
      expect(response.headers['Content-Disposition']).to eq(
        "inline; filename=\"hello.jpg\"; filename*=UTF-8''hello.jpg"
      )
      expect(response.body).to eq 'Hello world!'
    end

    it 'returns the blob as attachment' do
      get blob.service_url(disposition: :attachment)

      expect(response).to have_http_status(:ok)
      expect(response.content_type).to eq('image/jpg')
      expect(response.headers['Content-Disposition']).to eq(
        "attachment; filename=\"hello.jpg\"; filename*=UTF-8''hello.jpg"
      )
      expect(response.body).to eq 'Hello world!'
    end

    context 'with a deleted blob' do
      let!(:blob) { create_blob }

      before { blob.delete }

      it 'returns not found' do
        get blob.service_url

        expect(response).to have_http_status(:not_found)
      end
    end

    context 'with an invalid key' do
      let(:engine_url_helpers) { ::ActiveStorageDB::Engine.routes.url_helpers }

      it 'returns not found' do
        get engine_url_helpers.service_path(encoded_key: 'Invalid key', filename: 'hello.txt')
        expect(response).to have_http_status(:not_found)
      end
    end
  end

  describe '.update' do
    let(:data) { 'Something else entirely!' }
    let(:blob) { create_blob_before_direct_upload(byte_size: data.size, checksum: Digest::MD5.base64digest(data)) }

    it 'uses blob direct upload with integrity' do
      put blob.service_url_for_direct_upload, params: data, headers: { 'Content-Type' => 'text/plain' }

      expect(response).to have_http_status(:no_content)
      expect(data).to eq blob.download
    end

    it 'uses blob direct upload with mismatched content type' do
      put blob.service_url_for_direct_upload, params: data, headers: { 'Content-Type' => 'application/octet-stream' }

      expect(response).to have_http_status(:unprocessable_entity)
      expect(blob.service.exist?(blob.key)).to be_falsey
    end

    context 'with an invalid checksum' do
      let(:blob) do
        create_blob_before_direct_upload(byte_size: data.size, checksum: Digest::MD5.base64digest('bad data'))
      end

      it 'fails to upload' do
        put blob.service_url_for_direct_upload, params: data

        expect(response).to have_http_status(:unprocessable_entity)
        expect(blob.service.exist?(blob.key)).to be_falsey
      end
    end

    context 'with an invalid content length' do
      let(:blob) { create_blob_before_direct_upload byte_size: data.size - 1, checksum: Digest::MD5.base64digest(data) }

      it 'fails to upload' do
        put blob.service_url_for_direct_upload, params: data, headers: { 'Content-Type' => 'text/plain' }

        expect(response).to have_http_status(:unprocessable_entity)
        expect(blob.service.exist?(blob.key)).to be_falsey
      end
    end

    context 'with an invalid token' do
      let(:engine_url_helpers) { ::ActiveStorageDB::Engine.routes.url_helpers }

      it 'returns not found' do
        put engine_url_helpers.update_service_path(encoded_token: 'Invalid token')
        expect(response).to have_http_status(:not_found)
      end
    end
  end
end
