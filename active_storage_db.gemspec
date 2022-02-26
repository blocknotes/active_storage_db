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

  spec.required_ruby_version = '>= 2.6.0'

  # Prevent pushing this gem to RubyGems.org. To allow pushes either set the 'allowed_push_host'
  # to allow pushing to a single host or delete this section to allow pushing to any host.
  if spec.respond_to?(:metadata)
    # spec.metadata['allowed_push_host'] = "TODO: Set to 'http://mygemserver.com'"
  else
    raise 'RubyGems 2.0 or newer is required to protect against ' \
      'public gem pushes.'
  end

  spec.files = Dir["{app,config,db,lib}/**/*", 'MIT-LICENSE', 'Rakefile', 'README.md']

  spec.add_dependency 'activestorage', '~> 6.0'
  spec.add_dependency 'rails', '~> 6.0'

  spec.add_development_dependency 'appraisal', '~> 2.4'
  spec.add_development_dependency 'factory_bot_rails', '~> 6.1'
end
