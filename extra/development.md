# Development

There 3 ways to interact with this project:

1) Using Docker:

```sh
# Run rails server on the dummy app (=> http://localhost:3000 to access to ActiveAdmin):
make up
# Enter in a Rails console (with the dummy app started):
make console
# Enter in a shell (with the dummy app started):
make shell
# Run the linter on the project (with the dummy app started):
make lint
# Run the test suite (with the dummy app started):
make specs
# Remove container and image:
make cleanup
# To try different versions of Ruby/Rails/ActiveAdmin edit docker-compose.yml
# For more commands please check the Makefile
```

2) Using Appraisal:

```sh
export RAILS_ENV=development
# Install dependencies:
bin/appraisal
# Run server (or any command):
bin/appraisal rails s
# Or with a specific configuration:
bin/appraisal rails80-activeadmin rails s
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
# To try different versions of Rails/ActiveAdmin edit extra/dev_setup.sh
```

Sample code to attach a file:

```ruby
# Create a test post in the dummy app
post = Post.create!(title: "test1")
post.some_file.attach(io: Rails.root.join("../../README.md").open, filename: "README.md")
```

## Releases

```sh
# Update lib/active_storage_db/version.rb with the new version
# Update the gemfiles:
bin/appraisal
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
