# frozen_string_literal: true

RSpec.describe "File controller" do
  def unprocessable
    Rails::VERSION::MAJOR > 7 || (Rails::VERSION::MAJOR == 7 && Rails::VERSION::MINOR >= 1) ? :unprocessable_content : :unprocessable_entity
  end

  let(:blob) { create_blob(filename: "img.jpg", content_type: "image/jpeg") }
  let(:url_options) do
    {
      protocol: "http://",
      host: "test.example.com",
      port: "3001"
    }
  end
  let(:host) { "#{url_options[:protocol]}#{url_options[:host]}:#{url_options[:port]}" }
  let(:engine_url_helpers) { ActiveStorageDB::Engine.routes.url_helpers }

  before do
    if ActiveStorage::Current.respond_to? :url_options
      allow(ActiveStorage::Current).to receive(:url_options).and_return(url_options)
    else
      allow(ActiveStorage::Current).to receive(:host).and_return(host)
    end
  end

  it "creates a new File entity in the DB" do
    expect { create_blob }.to change(ActiveStorageDB::File, :count).from(0).to(1)
  end

  describe ".show" do
    it "returns the blob as inline" do
      blob_url = blob.respond_to?(:url) ? blob.url : blob.service_url

      get blob_url

      expect(response).to have_http_status(:ok)
      expect(response.content_type).to eq("image/jpeg")
      content_disposition = response.headers["Content-Disposition"]
      expect(content_disposition).to eq("inline; filename=\"img.jpg\"; filename*=UTF-8''img.jpg")
      expect(response.body).to eq "Hello world!"
    end

    it "returns the blob as attachment" do
      url = blob.respond_to?(:url) ? blob.url(disposition: :attachment) : blob.service_url(disposition: :attachment)
      get url

      expect(response).to have_http_status(:ok)
      expect(response.content_type).to eq("image/jpeg")
      content_disposition = response.headers["Content-Disposition"]
      expect(content_disposition).to eq("attachment; filename=\"img.jpg\"; filename*=UTF-8''img.jpg")
      expect(response.body).to eq "Hello world!"
    end

    context "with a blob that has no content type" do
      let(:blob) { create_blob(filename: "data.bin", content_type: "application/octet-stream") }

      it "serves the file with the stored content type", :aggregate_failures do
        blob_url = blob.respond_to?(:url) ? blob.url : blob.service_url
        get blob_url

        expect(response).to have_http_status(:ok)
        expect(response.content_type).to eq("application/octet-stream")
        expect(response.body).to eq "Hello world!"
      end
    end

    context "with a deleted blob" do
      let!(:blob) { create_blob }

      before { blob.delete }

      it "returns not found" do
        blob_url = blob.respond_to?(:url) ? blob.url : blob.service_url
        get blob_url

        expect(response).to have_http_status(:not_found)
      end
    end

    context "with an invalid key" do
      it "returns not found", :aggregate_failures do
        get blob.respond_to?(:url) ? blob.url : blob.service_url
        expect(response).to have_http_status(:ok)

        invalid_key = [blob.key, "_"].join
        get engine_url_helpers.service_path(encoded_key: invalid_key, filename: "hello.txt")
        expect(response).to have_http_status(:not_found)
      end
    end
  end

  describe ".update" do
    let(:data) { "Something else entirely!" }
    let(:blob) { create_blob_before_direct_upload(byte_size: data.size, checksum: Digest::MD5.base64digest(data)) }

    it "uses blob direct upload with integrity" do
      put blob.service_url_for_direct_upload, params: data, headers: { "Content-Type" => "text/plain" }

      expect(response).to have_http_status(:no_content)
      expect(blob.download).to eq data
    end

    it "uses blob direct upload with mismatched content type" do
      put blob.service_url_for_direct_upload, params: data, headers: { "Content-Type" => "application/octet-stream" }

      expect(response).to have_http_status(unprocessable)
      expect(blob.service).not_to exist(blob.key)
    end

    context "with an invalid checksum" do
      let(:blob) do
        create_blob_before_direct_upload(byte_size: data.size, checksum: Digest::MD5.base64digest("bad data"))
      end

      it "fails to upload" do
        put blob.service_url_for_direct_upload, params: data

        expect(response).to have_http_status(unprocessable)
        expect(blob.service).not_to exist(blob.key)
      end
    end

    context "with an invalid content length" do
      let(:blob) { create_blob_before_direct_upload byte_size: data.size - 1, checksum: Digest::MD5.base64digest(data) }

      it "fails to upload" do
        put blob.service_url_for_direct_upload, params: data, headers: { "Content-Type" => "text/plain" }

        expect(response).to have_http_status(unprocessable)
        expect(blob.service).not_to exist(blob.key)
      end
    end

    context "with an invalid token" do
      it "returns not found", :aggregate_failures do
        get blob.respond_to?(:url) ? blob.url : blob.service_url
        expect(response).to have_http_status(:not_found)

        put engine_url_helpers.update_service_path(encoded_token: "Invalid token")
        expect(response).to have_http_status(:not_found)
      end
    end

    context "when the integrity check fails" do
      it "fails to upload and does not persist the file", :aggregate_failures do
        allow(blob.service).to receive(:upload).and_raise(ActiveStorage::IntegrityError)

        put blob.service_url_for_direct_upload, params: data, headers: { "Content-Type" => "text/plain" }

        expect(response).to have_http_status(unprocessable)
        expect(blob.service).not_to exist(blob.key)
      end
    end
  end
end
