# frozen_string_literal: true

RSpec.describe 'active_storage_db_tasks' do
  include_context 'rake context'

  describe 'asdb:ls' do
    subject(:task) { execute_task('asdb:ls') }

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
end
