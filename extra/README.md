# Development

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
