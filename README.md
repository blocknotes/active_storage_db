# Active Storage DB

[![gem version](https://badge.fury.io/rb/active_storage_db.svg)](https://badge.fury.io/rb/active_storage_db)
[![gem downloads](https://badgen.net/rubygems/dt/active_storage_db)](https://rubygems.org/gems/active_storage_db)
[![maintainability](https://api.codeclimate.com/v1/badges/92e1e703c308744a0f66/maintainability)](https://codeclimate.com/github/blocknotes/active_storage_db/maintainability)

[![linters](https://github.com/blocknotes/active_storage_db/actions/workflows/linters.yml/badge.svg)](https://github.com/blocknotes/active_storage_db/actions/workflows/linters.yml)
[![specs Postgres](https://github.com/blocknotes/active_storage_db/actions/workflows/specs_postgres_71.yml/badge.svg)](https://github.com/blocknotes/active_storage_db/actions/workflows/specs_postgres_71.yml)
[![specs MySQL](https://github.com/blocknotes/active_storage_db/actions/workflows/specs_mysql_71.yml/badge.svg)](https://github.com/blocknotes/active_storage_db/actions/workflows/specs_mysql_71.yml)

An Active Storage service upload/download plugin that stores files in a PostgreSQL or MySQL database. Experimental support also for MSSQL.

Main features:
- attachment data stored in a binary field (or blob);
- all service methods implemented;
- supports Rails _6_ and _7_.

Useful also with platforms like Heroku (due to their ephemeral file system).

## Installation

- Setup Active Storage in your Rails application
- Add to your Gemfile `gem 'active_storage_db'` (and execute: `bundle`)
- Install the gem migrations: `bin/rails active_storage_db:install:migrations` (and execute: `bin/rails db:migrate`)
- Add to your `config/routes.rb`: `mount ActiveStorageDB::Engine => '/active_storage_db'`
- Change Active Storage service in *config/environments/development.rb* to: `config.active_storage.service = :db`
- Add to *config/storage.yml*:

```yml
db:
  service: DB
```

If there is a need to support a separate database connection for storing the `ActiveStorageDB` files:

1. Add a separate database configuration for the environment (this one is just an example)

```yml
attachments:
  database: attachments
  pool: 5
  username: root
  migrations_paths: config/attachments_migrate
```

2. Create a separate initializer file in `config/initializera/active_storage_db.rb` to set the database:

```rb
# app/overrides/models/active_storage_db/application_record_override.rb
ActiveStorageDB::ApplicationRecord.class_eval do
  connects_to database: { reading: :attachments, writing: :attachments }
end
```

3. Move the `ActiveStorageDB` related migrations to a configured storage migrations path
4. Create the database and execute the migrations

## Misc

Some utility tasks are available:

```sh
# list attachments ordered by blob id desc (with limit 100):
bin/rails 'asdb:list'
# search attachments by filename (or part of it)
bin/rails 'asdb:search[some_filename]'
# download attachment by blob id (retrieved with list or search tasks) - the second argument is the destination:
bin/rails 'asdb:download[123,/tmp]'
```

## Do you like it? Star it!

If you use this component just star it. A developer is more motivated to improve a project when there is some interest.

Or consider offering me a coffee, it's a small thing but it is greatly appreciated: [about me](https://www.blocknot.es/about-me).

## Contributors

- [Mattia Roccoberton](https://blocknot.es/): author
- Inspired by [activestorage-database-service](https://github.com/TitovDigital/activestorage-database-service) project

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
