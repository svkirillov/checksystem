#!/usr/bin/env sh

docker-compose stop cs
docker-compose rm -f cs
docker-compose run -d --rm --service-ports --name checksystem cs noinit
