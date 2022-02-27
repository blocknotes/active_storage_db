# frozen_string_literal: true

RSpec.describe 'ActiveStorageDB tasks' do
  include_context 'with rake tasks'

  describe 'asdb:list' do
    subject(:task) { execute_task('asdb:list') }

    let(:file1) { create(:active_storage_blob, filename: 'some file 1', created_at: Time.now - 1.hour) }
    let(:file2) { create(:active_storage_blob, filename: 'some file 2', created_at: Time.now - 5.hour) }
    let(:file3) { create(:active_storage_blob, filename: 'some file 3', created_at: Time.now - 3.hour) }

    before do
      [file1, file2, file3]
    end

    it 'prints the columns header + the list of 3 files', :aggregate_failures do
      pattern = /#{file3.id}  #{file3.filename}.+#{file2.id}  #{file2.filename}.+#{file1.id}  #{file1.filename}/m
      expect(task).to match pattern
      expect(task.split("\n").size).to be 4
    end
  end

  describe 'asdb:download' do
    subject(:task) { execute_task('asdb:download') }

    it 'exits showing the required arguments' do
      with_captured_stderr do
        expect { task }.to raise_exception(SystemExit, /Required arguments: source blob id, destination path/)
      end
    end

    context 'with a missing source' do
      subject(:task) { execute_task('asdb:download', blob_id: 'some_file') }

      before do
        allow(File).to receive(:writable?).and_return(true)
      end

      it 'exits showing a not found error' do
        with_captured_stderr do
          expect { task }.to raise_exception(SystemExit, /Source file not found/)
        end
      end
    end

    context 'with an invalid destination' do
      subject(:task) { execute_task('asdb:download', blob_id: 'some_file', destination: 'some_path') }

      let(:blob) { build_stubbed(:active_storage_blob) }

      before do
        allow(File).to receive(:writable?).and_return(false)
        allow(ActiveStorage::Blob).to receive(:find_by).and_return(blob)
      end

      it 'exits showing a write error' do
        with_captured_stderr do
          expect { task }.to raise_exception(SystemExit, /Can't write on/)
        end
      end
    end

    context 'with valid arguments' do
      subject(:task) { execute_task('asdb:download', blob_id: 'some_file', destination: 'some_path') }

      let(:blob) { build_stubbed(:active_storage_blob) }

      before do
        allow(File).to receive_messages(binwrite: 1000, writable?: true)
        allow(ActiveStorage::Blob).to receive(:find_by).and_return(blob)
        allow(blob).to receive(:download).and_return('some data')
      end

      it 'prints the number of bytes written' do
        expect(task).to eq "1000 bytes written - some_path\n"
      end
    end
  end

  describe 'asdb:search' do
    subject(:task) { execute_task('asdb:search') }

    let(:blob) { build_stubbed(:active_storage_blob) }

    it 'exits showing the required arguments' do
      with_captured_stderr do
        expect { task }.to raise_exception(SystemExit, /Required arguments/)
      end
    end

    context 'when no files are found' do
      subject(:task) { execute_task('asdb:search', filename: 'just ') }

      it 'prints "No results" message' do
        expect(task).to eq "No results\n"
      end
    end

    context 'with there are some results' do
      subject(:task) { execute_task('asdb:search', filename: 'just ') }

      before do
        create(:active_storage_blob, filename: 'just a file', created_at: Time.now - 1.hour)
        create(:active_storage_blob, filename: 'just another file', created_at: Time.now - 5.hour)
        create(:active_storage_blob, filename: 'the last file', created_at: Time.now - 3.hour)
      end

      it 'prints the files that matches', :aggregate_failures do
        expect(task).to match /just another file.+just a file/m
        expect(task.split("\n").size).to be 3
      end
    end
  end
end
