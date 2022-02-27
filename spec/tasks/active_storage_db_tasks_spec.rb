# frozen_string_literal: true

RSpec.describe 'ActiveStorageDB tasks' do
  include_context 'with rake tasks'

  describe 'asdb:list' do
    subject(:task) { execute_task('asdb:list') }

    let(:file1) { create(:active_storage_blob, filename: 'file1', created_at: Time.now - 1.hour) }
    let(:file2) { create(:active_storage_blob, filename: 'file2', created_at: Time.now - 5.hour) }
    let(:file3) { create(:active_storage_blob, filename: 'file3', created_at: Time.now - 3.hour) }

    before do
      [file1, file2, file3]
    end

    it { is_expected.to match /file1.+file2.+file3/m }

    it 'prints the list of 3 files' do
      expect(task.split("\n").size).to be 3
    end
  end

  describe 'asdb:get' do
    subject(:task) { execute_task('asdb:get') }

    it 'exits showing the required arguments' do
      with_captured_stderr do
        expect { task }.to raise_exception(SystemExit, /Required arguments/)
      end
    end

    context 'with only the source specified' do
      subject(:task) { execute_task('asdb:get', src: 'some_file') }

      it 'exits showing the required arguments' do
        with_captured_stderr do
          expect { task }.to raise_exception(SystemExit, /Required arguments/)
        end
      end
    end

    context 'with an invalid destination' do
      subject(:task) { execute_task('asdb:get', src: 'some_file', dst: 'some_path') }

      before do
        allow(File).to receive(:writable?).and_return(false)
      end

      it 'exits showing a write error' do
        with_captured_stderr do
          expect { task }.to raise_exception(SystemExit, /Can't write on/)
        end
      end
    end

    context 'with a missing source' do
      subject(:task) { execute_task('asdb:get', src: 'some_file', dst: 'some_path') }

      before do
        allow(File).to receive(:writable?).and_return(true)
      end

      it 'exits showing a not found error' do
        with_captured_stderr do
          expect { task }.to raise_exception(SystemExit, /Source file not found/)
        end
      end
    end

    context 'with valid arguments' do
      subject(:task) { execute_task('asdb:get', src: blob.filename.to_s, dst: 'some_path') }

      let(:blob) { build_stubbed(:active_storage_blob) }
      let(:blobs) { instance_double(ActiveRecord::Relation) }

      before do
        allow(File).to receive_messages(binwrite: 1000, writable?: true)
        allow(ActiveStorage::Blob).to receive(:order).and_return(blobs)
        allow(blobs).to receive(:find_by).and_return(blob)
        allow(blob).to receive(:download).and_return('some data')
      end

      it 'prints the number of bytes written' do
        expect(task).to eq "1000 bytes written\n"
      end
    end
  end
end
