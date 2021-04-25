# frozen_string_literal: true

require 'simplecov'
SimpleCov.start :rails do
  filters.clear
  add_filter %r{^/spec/}
  add_filter %r{^/lib/active_storage_db/version.rb}
end

require 'spec_helper'
ENV['RAILS_ENV'] ||= 'test'
require File.expand_path('dummy/config/environment.rb', __dir__)

abort('The Rails environment is running in production mode!') if Rails.env.production?
require 'rspec/rails'
require 'factory_bot_rails'

support_files = File.expand_path('support/**/*.rb', __dir__)
Dir[support_files].sort.each { |f| require f }

begin
  ActiveRecord::Migration.maintain_test_schema!
rescue ActiveRecord::PendingMigrationError => e
  puts e.to_s.strip
  exit 1
end

RSpec.configure do |config|
  config.fixture_path = "#{::Rails.root}/spec/fixtures"
  # config.use_transactional_fixtures = true
  config.infer_spec_type_from_file_location!
  config.filter_rails_from_backtrace!
end
