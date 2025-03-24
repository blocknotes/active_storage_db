# frozen_string_literal: true

source 'https://rubygems.org'
git_source(:github) { |repo| "https://github.com/#{repo}.git" }

ruby_ver = ENV.fetch("RUBY_VERSION", "")
rails_ver = ENV.fetch("RAILS_VERSION", "")

if ENV['DEVEL'] == '1'
  if !rails_ver.empty?
    gem 'rails', "~> #{rails_ver}"
  else
    gem 'rails'
  end

  gem 'active_storage_db', path: './'
  gem 'appraisal', '~> 2.4'
  gem 'factory_bot_rails', '~> 6.1'
else
  gemspec
end

# DB driver: mssql
gem 'activerecord-sqlserver-adapter'
gem 'tiny_tds'

# DB driver: mysql
gem 'mysql2'

# DB driver: postgres
gem 'pg'

# DB driver: sqlite
if !rails_ver.empty? && Gem::Version.new(rails_ver) < Gem::Version.new('7.2')
  gem 'sqlite3', '~> 1.4'
else
  gem 'sqlite3'
end

if !ruby_ver.empty? && Gem::Version.new(ruby_ver) < Gem::Version.new('3.2')
  gem 'zeitwerk', '~> 2.6.18'
end

# NOTE: to avoid error: uninitialized constant ActiveSupport::LoggerThreadSafeLevel::Logger
gem 'concurrent-ruby', '1.3.4'

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
