# Development

## Releases

```sh
# Update lib/active_storage_db/version.rb with the new version
# Update the gemfiles:
bin/appraisal
```

## Local tests

```sh
# Running tests on Rails 6.0:
DB_TEST=postgres RAILS=6.0 bin/appraisal rails-6_0-postgres rails db:test:prepare
DB_TEST=postgres RAILS=6.0 bin/appraisal rails-6_0-postgres rspec

# Running tests on Rails 6.1:
DB_TEST=postgres RAILS=6.1 bin/appraisal rails-6_1-postgres rails db:test:prepare
DB_TEST=postgres RAILS=6.1 bin/appraisal rails-6_1-postgres rspec

# Running tests on Rails 7.0:
DB_TEST=postgres RAILS=7.0 bin/appraisal rails-7_0-postgres rails db:test:prepare
DB_TEST=postgres RAILS=7.0 bin/appraisal rails-7_0-postgres rspec

# Eventually recreate the DB:
DB_TEST=postgres RAILS=7.0 bin/appraisal rails-7_0-postgres rails db:drop db:create db:migrate
```

## Tests using Docker

```sh
# Run a specific test configuration
docker-compose up --abort-on-container-exit -- tests_26_mysql
docker-compose up --abort-on-container-exit -- tests_26_pg
docker-compose up --abort-on-container-exit -- tests_27_mysql
docker-compose up --abort-on-container-exit -- tests_27_pg
# Cleanup (also removing local images):
docker-compose down --rmi local
```
