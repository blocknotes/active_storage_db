# Development

There 3 ways to interact with this project:

1) Using Docker:

```sh
# Set the test DB driver (mysql / mssql / postgres / sqlite)
export DB=sqlite
# Start the base service (in the test dummy app):
make up
# With the base service started, start the Rails server (default port 4000):
make server
# With the base service started, enter in a shell:
make shell

# With the base service started, run the test suite:
make specs
# With the base service started, run the linter on the project:
make lint

# Remove container and image:
make cleanup
# For more commands please check the Makefile

# To use a different db, Ruby and Rails:
DB=postgres RUBY=3.4 RAILS=7.2 make up
```

2) Using Appraisal:

```sh
export RAILS_ENV=development
# Install dependencies:
bin/appraisal
# Run server (or any command):
bin/appraisal rails s
# Or with a specific configuration:
bin/appraisal postgres_ruby32_rails80 rails s
```

3) With a local setup:

```sh
# Dev setup (set the required envs):
source extra/dev_setup.sh
# Install dependencies:
bundle update
# Prepare the app
bin/rails db:reset
# Run server (or any command):
bin/rails s
# To try different versions of Rails edit extra/dev_setup.sh
```

### Useful commands

Sample code to attach a file:

```ruby
# Create a test post in the dummy app
post = Post.last || Post.create!(title: "test1")
io = Rails.root.join("public/favicon.ico").open
post.some_file.attach(io:, filename: "favicon.ico")
```

## Releases

```sh
# Update lib/active_storage_db/version.rb with the new version

# Update the gemfiles:
make cleanup
RUBY=3.0 make appraisal_update

make cleanup
RUBY=3.2 make appraisal_update

make cleanup
RUBY=3.4 make appraisal_update
```

## Old dev setup

Local tests:

```sh
# Running tests on Rails 6.1:
DB_TEST=postgres bin/appraisal rails-6_1-postgres rails db:test:prepare
DB_TEST=postgres bin/appraisal rails-6_1-postgres rspec

# Running tests on Rails 7.0:
DB_TEST=postgres bin/appraisal rails-7_0-postgres rails db:test:prepare
DB_TEST=postgres bin/appraisal rails-7_0-postgres rspec

# Running tests on Rails 7.1:
DB_TEST=postgres bin/appraisal rails-7_1-postgres rails db:test:prepare
DB_TEST=postgres bin/appraisal rails-7_1-postgres rspec

# Eventually recreate the DB:
DB_TEST=postgres bin/appraisal rails-7_0-postgres rails db:drop db:create db:migrate
```

Using docker:

```sh
# Run a specific test configuration
docker compose up --abort-on-container-exit -- tests_30_mysql
docker compose up --abort-on-container-exit -- tests_30_postgres
# Cleanup (also removing local images):
docker compose down --rmi local
```
