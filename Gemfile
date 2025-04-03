# frozen_string_literal: true

source 'https://rubygems.org'
git_source(:github) { |repo| "https://github.com/#{repo}.git" }

if ENV['DEVEL'] == '1'
  gem 'active_storage_db', path: './'
else
  gemspec
end

ruby_ver = ENV.fetch('RUBY_VERSION', '')
rails_ver = ENV.fetch('RAILS_VERSION', '')

rails = rails_ver.empty? ? ['rails'] : ['rails', "~> #{rails_ver}"]
gem(*rails)

ruby32 = Gem::Version.new(ruby_ver) >= Gem::Version.new('3.2')
gem 'zeitwerk', '~> 2.6.18' unless ruby32

# DB driver: mssql
gem 'activerecord-sqlserver-adapter'
gem 'tiny_tds'

# DB driver: mysql
gem 'mysql2'

# DB driver: postgres
gem 'pg'

# DB driver: sqlite
rails72 = Gem::Version.new(rails_ver) >= Gem::Version.new('7.2')
sqlite3 = ruby32 || rails72 ? ['sqlite3'] : ['sqlite3', '~> 1.4']
gem(*sqlite3)

# NOTE: to avoid error: uninitialized constant ActiveSupport::LoggerThreadSafeLevel::Logger
gem 'concurrent-ruby', '1.3.4'

gem 'bigdecimal'
gem 'image_processing', '>= 1.2'
gem 'mutex_m'
gem 'puma'
gem 'sprockets-rails'

# Testing
gem 'capybara'
gem 'factory_bot_rails'
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
