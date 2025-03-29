#!/bin/sh

while ! nc -z $DB_TEST $DB_PORT </dev/null
do echo "Waiting for DB ($DB_TEST)..." && sleep 3; done
echo "DB is now available!"
