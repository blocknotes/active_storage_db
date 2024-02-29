# Development

## Releases

```sh
# Update lib/active_storage_db/version.rb with the new version
# Update the gemfiles:
bin/appraisal
```

## Local tests

```sh
# Running tests on Rails 6.1:
DB_TEST=postgres RAILS=6.1 bin/appraisal rails-6_1-postgres rails db:test:prepare
DB_TEST=postgres RAILS=6.1 bin/appraisal rails-6_1-postgres rspec

# Running tests on Rails 7.0:
DB_TEST=postgres RAILS=7.0 bin/appraisal rails-7_0-postgres rails db:test:prepare
DB_TEST=postgres RAILS=7.0 bin/appraisal rails-7_0-postgres rspec

# Running tests on Rails 7.1:
DB_TEST=postgres RAILS=7.0 bin/appraisal rails-7_1-postgres rails db:test:prepare
DB_TEST=postgres RAILS=7.0 bin/appraisal rails-7_1-postgres rspec

# Eventually recreate the DB:
DB_TEST=postgres RAILS=7.0 bin/appraisal rails-7_0-postgres rails db:drop db:create db:migrate
```

```ruby
# Create a test post in the dummy app
post = Post.create!(title: "test1")
post.some_file.attach(io: Rails.root.join("../../README.md").open, filename: "README.md")
```

## Tests using Docker

```sh
# Run a specific test configuration
docker compose up --abort-on-container-exit -- tests_30_mysql
docker compose up --abort-on-container-exit -- tests_30_postgres
# Cleanup (also removing local images):
docker compose down --rmi local
```
