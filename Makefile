include .env

help:
	@echo "Main targets: build / up / specs / console / shell"

# Docker commands
# build:
# 	@rm -f Gemfile.lock
# 	@docker compose build

# down:
# 	@docker compose down

# up: build
# 	@docker compose up

# cleanup:
# 	@docker compose rm -f
# 	@docker image rm -f ${COMPOSE_PROJECT_NAME}-app

# App commands
# server: build
# 	COMMAND="bin/rails s -b 0.0.0.0 -p 4000" docker compose up

# specs: build
# 	COMMAND="bin/rspec" docker compose up

# appraisal_update: build
# 	COMMAND="bin/appraisal update" docker compose up

# lint: build
# 	COMMAND="bin/rubocop" docker compose up

# console:
# 	docker compose exec -e "PAGER=more" app bin/rails console

# shell:
# 	docker compose exec -e "PAGER=more" app bash

build:
	@rm -f Gemfile.lock
	@docker compose build --no-cache --build-arg DB_TEST=${DB} app_with_${DB}

up: build
	@COMMAND="extra/wait_db.sh" docker compose up app_with_${DB}
	@COMMAND="bin/rails db:create db:migrate db:test:prepare" docker compose up app_with_${DB}
	@docker compose up app_with_${DB}

down:
	@docker compose down --remove-orphans app_with_${DB}

specs:
	@docker compose exec app_with_${DB} bin/rspec --fail-fast

shell:
	@docker compose exec app_with_${DB} bash

cleanup: down
	@docker compose rm --stop --volumes app_with_${DB}
	@docker image rm --force ${COMPOSE_PROJECT_NAME}-app_with_${DB}
