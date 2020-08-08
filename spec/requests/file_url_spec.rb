# frozen_string_literal: true

RSpec.describe 'File URL', type: :request do
  let(:app_url_helpers) { Rails.application.routes.url_helpers }
  let(:engine_url_helpers) { ::ActiveStorageDB::Engine.routes.url_helpers }

  it 'has the service URL in the engine URL helpers' do
    expect(app_url_helpers).to respond_to :active_storage_db_path
    expect(engine_url_helpers).to respond_to :service_url
  end
end
