# frozen_string_literal: true

source 'https://rubygems.org'
git_source(:github) { |repo| "https://github.com/#{repo}.git" }

if ENV['DEVEL'] == '1'
  rails_ver = ENV.fetch('RAILS_VERSION')
  gem 'rails', rails_ver

  gem 'active_storage_db', path: './'
  gem 'appraisal', '~> 2.4'
  gem 'factory_bot_rails', '~> 6.1'

  if rails_ver.start_with?('7.0')
    gem 'concurrent-ruby', '1.3.4'
  end
else
  gemspec
end

if ENV['DB_TEST'] == 'mssql'
  gem 'activerecord-sqlserver-adapter', '7.0.3.0'
  gem 'tiny_tds'
end
gem 'mysql2' if ENV['DB_TEST'] == 'mysql'
gem 'pg' if ['postgres', 'postgresql'].include? ENV['DB_TEST']
gem 'sqlite3' if ENV['DB_TEST'] == 'sqlite'

gem 'zeitwerk', '~> 2.6.18' # from 2.7 Ruby 3.2 is required

gem 'bigdecimal'
gem 'image_processing', '>= 1.2'
gem 'mutex_m'
gem 'puma'
gem 'sprockets-rails'

# Testing
gem 'capybara'
gem 'rspec_junit_formatter'
gem 'rspec-rails'
gem 'selenium-webdriver'
gem 'simplecov'
gem 'simplecov-lcov'

# Linters
gem 'brakeman'
gem 'fasterer'
gem 'rubocop'
gem 'rubocop-packaging'
gem 'rubocop-performance'
gem 'rubocop-rails'
gem 'rubocop-rspec'

# Tools
gem 'pry-rails'
