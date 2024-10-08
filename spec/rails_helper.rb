# frozen_string_literal: true

require 'simplecov'
require 'simplecov-lcov'

SimpleCov::Formatter::LcovFormatter.config do |c|
  c.report_with_single_file = true
  # c.single_report_path = ENV['LCOV_PATH'] if ENV['LCOV_PATH'].present?
end

simplecov_formatters = [
  SimpleCov::Formatter::LcovFormatter,
  SimpleCov.formatter
]
SimpleCov.formatter = SimpleCov::Formatter::MultiFormatter.new(simplecov_formatters)

SimpleCov.start :rails do
  filters.clear

  enable_coverage :branch

  add_filter %r{^/lib/active_storage_db/version.rb}
  add_filter %r{^/spec/}
  add_filter %r{^/vendor/}

  case ENV.fetch('RAILS', nil)
  when '6.1' then add_filter /_rails70|_rails71/
  when '7.0' then add_filter /_rails61|_rails71/
  when '7.1' then add_filter /_rails61|_rails70/
  end
end

require 'spec_helper'
ENV['RAILS_ENV'] ||= 'test'

app_ver = ENV.fetch('RAILS', '').tr('.', '')
require File.expand_path("dummy#{app_ver}/config/environment.rb", __dir__)

abort('The Rails environment is running in production mode!') if Rails.env.production?
require 'rspec/rails'
require 'factory_bot_rails'

support_files = File.expand_path('support/**/*.rb', __dir__)
Dir[support_files].sort.each { |f| require f }

# begin
#   ActiveRecord::Migration.maintain_test_schema!
# rescue ActiveRecord::PendingMigrationError => e
#   puts e.to_s.strip
#   exit 1
# end

RSpec.configure do |config|
  config.filter_rails_from_backtrace!
  config.infer_spec_type_from_file_location!
  config.use_transactional_fixtures = true

  config.before(:suite) do
    db_config =
      if ActiveRecord::Base.respond_to? :connection_db_config
        ActiveRecord::Base.connection_db_config.configuration_hash
      else
        ActiveRecord::Base.connection_config
      end

    intro = ('-' * 80)
    intro << "\n"
    intro << "- Ruby:          #{RUBY_VERSION}\n"
    intro << "- Rails:         #{Rails.version}\n"
    intro << "- ActiveStorage: #{ActiveStorage.version}\n"
    intro << "- DB adapter:    #{db_config[:adapter]}\n"
    intro << "- DB name:       #{db_config[:database]}\n"
    intro << ('-' * 80)

    RSpec.configuration.reporter.message(intro)
  end
end
