# frozen_string_literal: true

source 'https://rubygems.org'
git_source(:github) { |repo| "https://github.com/#{repo}.git" }

gemspec

group :development, :test do
  gem 'mysql2' if ENV['DB_TEST'] == 'mysql'
  gem 'pg' if ['postgres', 'postgresql'].include? ENV['DB_TEST']
  gem 'simplecov'
  gem 'simplecov-lcov'

  # Testing
  gem 'capybara'
  gem 'rspec_junit_formatter'
  gem 'rspec-rails'
  gem 'selenium-webdriver'

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
end
