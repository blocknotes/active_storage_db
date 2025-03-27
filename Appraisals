# frozen_string_literal: true

MATRIX = {
  "mssql" => {
    "3.0" => ["6.1", "7.0"],
    "3.2" => ["6.1", "7.0", "8.0"],
    "3.4" => ["8.0"]
  },
  "mysql" => {
    "3.0" => ["6.1", "7.1"],
    "3.2" => ["6.1", "7.1", "7.2", "8.0"],
    "3.4" => ["7.2", "8.0"]
  },
  "postgres" => {
    "3.0" => ["6.1", "7.1"],
    "3.2" => ["6.1", "7.1", "7.2", "8.0"],
    "3.4" => ["7.2", "8.0"]
  },
  "sqlite" => {
    "3.2" => ["7.2", "8.0"],
    "3.4" => ["7.2", "8.0"]
  }
}.freeze

ruby_version = ENV["RUBY_VERSION"]&.sub(/\.[^\.]+\z/, '')
MATRIX.each do |db, versions|
  versions.each do |ruby, rails|
    next if ruby_version && ruby != ruby_version

    rails.each do |version|
      appraise "#{db}_ruby#{ruby.delete('.')}_rails#{version.delete('.')}" do
        gem 'pg'
        gem 'rails', "~> #{version}.0"
      end
    end
  end
end
