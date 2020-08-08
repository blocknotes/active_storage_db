# Active Storage DB
An Active Storage service upload/download plugin that stores files in a PostgreSQL or MySQL database.

Main features:
- all service methods implemented;
- data is saved using a binary field (or blob);
- RSpec tests.

## Installation
- Setup Active Storage in your Rails application
- Add this line to your Gemfile: `gem 'active_storage_db'`
- And execute: `bundle`
- Install gem migrations: `bin/rails active_storage_db:install:migrations`
- And execute: `bin/rails db:migrate`
- Add to your `config/routes.rb`: `mount ActiveStorageDB::Engine => '/active_storage_db'`
- Change Active Storage service in *config/environments/development.rb* to: `config.active_storage.service = :db`
- Add to *config/storage.yml*:
```
db:
  service: DB
```

## Do you like it? Star it!
If you use this component just star it. A developer is more motivated to improve a project when there is some interest.

## Contributors
- [Mattia Roccoberton](https://blocknot.es/): author
- Inspired by [activestorage-database-service](https://github.com/TitovDigital/activestorage-database-service) project

## License
The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
