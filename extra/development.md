# Development

### Dev setup

There are 2 ways to interact with this project:

1) Using Docker:

```sh
# env var: DB with a value in sqlite / mysql / mssql / postgres

make up         # starts the dev services (optional env vars: RUBY / RAILS)
make specs      # run the tests (after up)
make lint       # run the linters (after up)
make server     # run the server (after up)
make shell      # open a shell (after up)
make down       # cleanup (after up)

# Example: DB=postgres RUBY=3.2 RAILS=7.1.0 make up
```

2) With a local setup:

```sh
# Dev setup (set the required envs):
source extra/dev_setup.sh
# Install dependencies:
bundle update
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
