#!/bin/sh

# Wait the DB
if [ "$DB_TEST" != "sqlite" ]; then
  while ! nc -z $DB_TEST $DB_PORT </dev/null
  do echo "Waiting for DB ($DB_TEST)..." && sleep 3; done
  echo "DB is now available!"
fi

# Setup database
bin/rails db:create db:migrate db:test:prepare

echo "> init: done."
