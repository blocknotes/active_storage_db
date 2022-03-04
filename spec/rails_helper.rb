# frozen_string_literal: true

require 'simplecov'
SimpleCov.start :rails do
  filters.clear
  add_filter %r{^/lib/active_storage_db/version.rb}
  add_filter %r{^/spec/}
  add_filter %r{^/vendor/}

  case ENV['RAILS']
  when '6.0' then add_filter /_rails61|_rails70/
  when '6.1' then add_filter /_rails60|_rails70/
  when '7.0' then add_filter /_rails60|_rails61/
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
  config.fixture_path = "#{::Rails.root}/spec/fixtures"
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
