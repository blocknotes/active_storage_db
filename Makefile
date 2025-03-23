help:
	@echo "Main targets: up / down / console / shell"

# Docker commands
down:
	docker compose down

up:
	docker compose up

attach:
	docker compose attach app

up_attach:
	docker compose up -d && docker compose attach app

cleanup:
	docker container rm -f active_storage_db_app && docker image rm -f active_storage_db-app

# Rails specific commands
db_reset:
	docker compose exec app bin/rails db_reset

console:
	docker compose exec -e "PAGER=more" app bin/rails console

routes:
	docker compose exec app bin/rails routes

specs:
	docker compose exec app bin/rspec --fail-fast

# Other commands
bundle:
	docker compose exec app bundle

shell:
	docker compose exec -e "PAGER=more" app bash

lint:
	docker compose exec app bin/rubocop
