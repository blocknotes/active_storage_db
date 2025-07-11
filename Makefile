include extra/.env

DB ?= sqlite

help:
	@echo -e "${COMPOSE_PROJECT_NAME} - Main project commands (required env var: DB with a value in sqlite / mysql / mssql / postgres):\n\
		make up   	# starts the dev services (optional env vars: RUBY / RAILS)\n\
		make specs	# run the tests (after up)\n\
		make lint 	# run the linters (after up)\n\
		make server	# run the server (after up)\n\
		make shell	# open a shell (after up)\n\
		make down 	# cleanup (after up)\n\n\
	Example: DB=postgres RUBY=3.2 RAILS=7.1.0 make up"

# System commands

build:
	@rm -f Gemfile.lock spec/dummy/db/*.sqlite3
	@docker compose -f extra/docker-compose.yml build --build-arg DB_TEST=${DB} app_with_${DB}

db_reset:
	@docker compose -f extra/docker-compose.yml run --rm app_with_${DB} extra/init.sh

up: build db_reset
	@docker compose -f extra/docker-compose.yml up app_with_${DB}

shell:
	@docker compose -f extra/docker-compose.yml exec app_with_${DB} bash

down:
	@docker compose -f extra/docker-compose.yml down --volumes --rmi local --remove-orphans

# App commands

console:
	@docker compose -f extra/docker-compose.yml exec app_with_${DB} bin/rails console

lint:
	@docker compose -f extra/docker-compose.yml exec app_with_${DB} bin/rubocop

seed:
	@docker compose -f extra/docker-compose.yml exec app_with_${DB} bin/rails db:seed

server:
	@docker compose -f extra/docker-compose.yml exec app_with_${DB} bin/rails server -b 0.0.0.0 -p ${SERVER_PORT}

specs:
	@docker compose -f extra/docker-compose.yml exec app_with_${DB} bin/rspec --fail-fast
