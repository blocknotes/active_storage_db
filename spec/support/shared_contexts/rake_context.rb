# frozen_string_literal: true

require "rake"

shared_context "with rake tasks" do
  before(:context) do
    Rails.application.load_tasks unless Rake::Task.task_defined?("environment")
  end

  def execute_task(task, args = nil)
    with_captured_stdout do
      Rake::Task[task].execute(args)
    end
  end

  def with_captured_stderr
    original_stderr = $stderr
    $stderr = StringIO.new
    yield
    $stderr.string
  ensure
    $stderr = original_stderr
  end

  def with_captured_stdout
    original_stdout = $stdout
    $stdout = StringIO.new
    yield
    $stdout.string
  ensure
    $stdout = original_stdout
  end
end
