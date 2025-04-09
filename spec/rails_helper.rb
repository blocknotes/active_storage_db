# frozen_string_literal: true

ENV['RAILS_ENV'] = 'test'

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
end

require 'spec_helper'

require File.expand_path("dummy/config/environment.rb", __dir__)

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

  config.add_setting :docker_container, default: nil

  config.before(:suite) do
    ruby_ver = ENV.fetch('RUBY', '3.4')

    config.docker_container = Testcontainers::DockerContainer.new("ruby:#{ruby_ver}-slim")
    config.docker_container.start

    # !!! Ruby version won't change because we are not running the whole test suite inside the container

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

  config.after(:suite) do
    config.docker_container&.stop
    config.docker_container&.remove
  end
end
