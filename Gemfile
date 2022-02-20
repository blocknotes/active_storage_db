# frozen_string_literal: true

source 'https://rubygems.org'
git_source(:github) { |repo| "https://github.com/#{repo}.git" }

gemspec

group :development, :test do
  gem 'capybara', '~> 3.33'
  gem 'database_cleaner-active_record', '~> 1.8'
  gem 'mysql2', '~> 0.5' if ENV['DB_TEST'] == 'mysql'
  gem 'pg', '~> 1.2' if ['postgres', 'postgresql'].include? ENV['DB_TEST']
  gem 'rspec_junit_formatter', '~> 0.4'
  gem 'rspec-rails', '~> 4.0'
  gem 'selenium-webdriver', '~> 3.142'
  gem 'simplecov', '~> 0.18'

  # Linters
  gem 'brakeman'
  gem 'fasterer'
  gem 'reek'
  gem 'rubocop'
  gem 'rubocop-packaging'
  gem 'rubocop-performance'
  gem 'rubocop-rails'
  gem 'rubocop-rspec'

  # Tools
  gem 'pry-rails'
end
