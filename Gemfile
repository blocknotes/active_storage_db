# frozen_string_literal: true

source 'https://rubygems.org'
git_source(:github) { |repo| "https://github.com/#{repo}.git" }

gemspec

group :development, :test do
  gem 'capybara'
  gem 'database_cleaner-active_record'
  gem 'mysql2' if ENV['DB_TEST'] == 'mysql'
  gem 'pg' if ['postgres', 'postgresql'].include? ENV['DB_TEST']
  gem 'rspec_junit_formatter'
  gem 'rspec-rails'
  gem 'selenium-webdriver'
  gem 'simplecov'

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
