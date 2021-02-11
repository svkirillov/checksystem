#!/usr/bin/env sh

DB_PASSWORD=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | head -c 8)
ROOT_PASSWORD=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | head -c 8)
FLAG_SECRET=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | head -c 8)

sed -i -E "s/'[a-zA-Z0-9]{8}'/'$DB_PASSWORD'/" create_db.sql
sed -i -E "s/cs:[a-zA-Z0-9]{8}/cs:$DB_PASSWORD/" ../c_s.conf
sed -i -E "s/\{auth => 'root:[a-zA-Z0-9]{8}'\}/\{auth => 'root:$ROOT_PASSWORD'\}/i" ../c_s.conf
sed -i -E "s/\{secret => '[a-zA-Z0-9]{8}'\}/\{secret => '$FLAG_SECRET'\}/i" ../c_s.conf

# docker volume rm docker_dbdata

docker-compose up -d
