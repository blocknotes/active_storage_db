# frozen_string_literal: true

$:.push File.expand_path('lib', __dir__)

# Maintain your gem's version:
require 'active_storage_db/version'

# Describe your gem and declare its dependencies:
Gem::Specification.new do |spec|
  spec.name        = 'active_storage_db'
  spec.version     = ActiveStorageDB::VERSION
  spec.authors     = ['Mattia Roccoberton']
  spec.email       = ['mat@blocknot.es']
  spec.homepage    = 'https://github.com/blocknotes/active_storage_db'
  spec.summary     = 'ActiveStorage DB Service'
  spec.description = 'An ActiveStorage service plugin to store files in database.'
  spec.license     = 'MIT'

  spec.required_ruby_version = '>= 2.7.0'

  spec.metadata['homepage_uri'] = spec.homepage
  spec.metadata['source_code_uri'] = spec.homepage
  spec.metadata['rubygems_mfa_required'] = 'true'

  spec.files = Dir["{app,config,db,lib}/**/*", 'MIT-LICENSE', 'Rakefile', 'README.md']

  spec.add_dependency 'activestorage', '>= 6.0'
  spec.add_dependency 'rails', '>= 6.0'

  spec.add_development_dependency 'appraisal', '~> 2.4' # rubocop:disable Gemspec/DevelopmentDependencies
  spec.add_development_dependency 'factory_bot_rails', '~> 6.1' # rubocop:disable Gemspec/DevelopmentDependencies
end
