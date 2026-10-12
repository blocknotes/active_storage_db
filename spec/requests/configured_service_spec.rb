# frozen_string_literal: true

RSpec.describe "Configured engine service" do
  let(:data) { "Database attachment" }
  let(:disk_service) { ActiveStorage::Blob.services.fetch(:test) }
  let(:blob) do
    ActiveStorage::Blob.create_and_upload!(
      io: StringIO.new(data), filename: "template.txt", content_type: "text/plain",
      service_name: "db"
    )
  end

  before do
    allow(ActiveStorage::Blob).to receive(:service).and_return(disk_service)
    if ActiveStorage::Current.respond_to?(:url_options)
      allow(ActiveStorage::Current).to receive(:url_options).and_return(protocol: "http://", host: "test.example.com")
    else
      allow(ActiveStorage::Current).to receive(:host).and_return("http://test.example.com")
    end
  end

  shared_examples "a configured DB service" do
    it "downloads from DB storage without changing the default service", :aggregate_failures do
      get blob.url

      expect(response).to have_http_status(:ok)
      expect(response.body).to eq(data)
      expect(ActiveStorage::Blob.service).to eq(disk_service)
      expect(disk_service).not_to exist(blob.key)
    end

    it "uploads directly to DB storage without changing the default service", :aggregate_failures do
      pending_blob = ActiveStorage::Blob.create_before_direct_upload!(
        filename: "template.txt", byte_size: data.bytesize, content_type: "text/plain",
        checksum: Digest::MD5.base64digest(data), service_name: "db"
      )

      put pending_blob.service_url_for_direct_upload, params: data, headers: { "Content-Type" => "text/plain" }

      expect(response).to have_http_status(:no_content)
      expect(pending_blob.download).to eq(data)
      expect(ActiveStorage::Blob.service).to eq(disk_service)
      expect(disk_service).not_to exist(pending_blob.key)
    end
  end

  context "with a symbol service name" do
    before { allow(Rails.application.config.active_storage_db).to receive(:service).and_return(:db) }

    it_behaves_like "a configured DB service"
  end

  context "with a string service name" do
    before { allow(Rails.application.config.active_storage_db).to receive(:service).and_return("db") }

    it_behaves_like "a configured DB service"
  end

  context "without a configured service" do
    before do
      allow(Rails.application.config.active_storage_db).to receive(:service).and_return(nil)
      allow(ActiveStorage::Blob).to receive(:service).and_return(ActiveStorage::Blob.services.fetch(:db))
    end

    it "downloads using the application's default service" do
      get blob.url

      expect(response).to have_http_status(:ok)
      expect(response.body).to eq(data)
    end
  end

  context "with an unknown service name" do
    before { allow(Rails.application.config.active_storage_db).to receive(:service).and_return(:missing_db) }

    it "raises the registry error instead of falling back" do
      expect { get blob.url }.to raise_error(KeyError, /missing_db/)
    end
  end
end
