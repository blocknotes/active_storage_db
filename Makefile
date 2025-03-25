include .env

help:
	@echo "Main targets: build / up / specs / console / shell"

# Docker commands
build:
	@rm -f Gemfile.lock
	@docker compose build

down:
	@docker compose down

up: build
	@docker compose up

cleanup:
	docker compose rm -f
	docker image rm -f ${COMPOSE_PROJECT_NAME}-app

# App commands
server: build
	COMMAND="bin/rails s -b 0.0.0.0 -p 4000" docker compose up

specs: build
	COMMAND="bin/rspec" docker compose up

appraisal_update: build
	COMMAND="bin/appraisal update" docker compose up

lint: build
	COMMAND="bin/rubocop" docker compose up

console:
	docker compose exec -e "PAGER=more" app bin/rails console

shell:
	docker compose exec -e "PAGER=more" app bash
