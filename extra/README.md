# Development

```sh
# Running tests on Rails 6.1:
DB_TEST=postgres bin/appraisal rails-6_1-postgres rspec
# Running tests on Rails 7.0:
DB_TEST=postgres RAILS_7=1 bin/appraisal rails-7_0-postgres rspec
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
