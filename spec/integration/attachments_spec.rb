# frozen_string_literal: true

RSpec.describe 'Attachments' do
  context 'with a new target entity' do
    let(:filename) { 'file1.txt' }
    let(:uploaded_file) do
      ActionDispatch::Http::UploadedFile.new(
        tempfile: file_fixture(filename),
        filename: filename,
        content_type: 'text/plain'
      )
    end
    let(:test_post) { Post.new(title: 'A test post', some_file: uploaded_file) }

    it 'creates the entity with the attached file', :aggregate_failures, :skip_bullet do
      expect { test_post.save! }.to change(ActiveStorageDB::File, :count).by(1)

      expect(test_post.some_file).to be_attached
      expect(test_post.some_file.download).to eq file_fixture(filename).read
    end
  end

  context 'with an existing target entity' do
    let(:filename) { 'file3.png' }

    let!(:test_post) { Post.create!(title: 'A test post') }

    it 'attaches the file to the target entity', :aggregate_failures do
      expect {
        test_post.some_file.attach(io: file_fixture(filename).open, filename: filename)
      }.to change(ActiveStorageDB::File, :count).from(0).to(1)

      if Rails::VERSION::MAJOR >= 7
        variant = test_post.some_file.variant(:thumb)
        expect { variant.processed }.to change(ActiveStorageDB::File, :count).by(1)
      end

      expect(test_post.some_file.attached?).to be true
      expect(test_post.some_file.download).to eq file_fixture(filename).binread

      blob_path = Rails.application.routes.url_helpers.rails_blob_path(test_post.some_file, only_path: true)
      expect(blob_path).to match %r[/rails/active_storage/.+#{filename}]

      expect {
        test_post.some_file.purge
      }.to change(ActiveStorageDB::File, :count).by(-1)
    end
  end
end
