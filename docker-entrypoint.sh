#!/bin/bash

set -e

if [ -n "$DATABASE_HOST" ]; then
  until nc -z -v -w30 "$DATABASE_HOST" 5432
  do
    echo "Waiting for postgres database connection..."
    sleep 1
  done
  echo "Database is up!"
fi

if [ -n "$ELASTICSEARCH_HOST" ]; then
  until nc -z -v -w30 "$ELASTICSEARCH_HOST" 9200
  do
    echo "Waiting for elasticsearch connection..."
    sleep 1
  done
  echo "Elasticsearch is up!"
fi

# Apply database migrations
if [[ "$APPLY_MIGRATIONS" = "1" ]]; then
    echo "Applying database migrations..."
    ./manage.py migrate --noinput
fi

# Create superuser
if [[ "$CREATE_SUPERUSER" = "1" ]]; then
    ./manage.py add_admin_user -u admin -p admin -e admin@example.com
    echo "Admin user created with credentials admin:admin (email: admin@example.com)"
fi

# Start server
if [[ ! -z "$@" ]]; then
    "$@"
elif [[ "$DEV_SERVER" = "1" ]]; then
    python ./manage.py runserver 0.0.0.0:8081
else
    uwsgi --ini .prod/uwsgi.ini
fi
