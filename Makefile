include extra/.env

help:
	@echo -e "Usage (with DB one value in sqlite / mysql / mssql / postgres):\n  DB=sqlite make up  # to start the base service\n  DB=sqlite make shell  # to enter in a shell\nCheck the Makefile for other commands"

build:
	@rm -f Gemfile.lock
	@docker compose -f extra/docker-compose.yml build --build-arg DB_TEST=${DB} app_with_${DB}

up: build
	@docker compose -f extra/docker-compose.yml up app_with_${DB}

shell:
	@docker compose -f extra/docker-compose.yml exec app_with_${DB} bash

specs:
	@docker compose -f extra/docker-compose.yml exec app_with_${DB} bin/rspec --fail-fast

console:
	@docker compose -f extra/docker-compose.yml exec app_with_${DB} bin/rails c

server:
	@docker compose -f extra/docker-compose.yml exec app_with_${DB} bin/rails s -b 0.0.0.0 -p ${SERVER_PORT}

appraisal_update:
	@docker compose -f extra/docker-compose.yml exec app_with_${DB} bin/appraisal update

lint:
	@docker compose -f extra/docker-compose.yml exec app_with_${DB} bin/rubocop

cleanup:
	@docker compose -f extra/docker-compose.yml down -v --rmi local --remove-orphans
