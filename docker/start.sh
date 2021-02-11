#!/usr/bin/env bash

PASSWORD=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | head -c 8)
sed -i -E "s/\{auth => 'root:[a-zA-Z0-9]{8}'\}/\{auth => 'root:$PASSWORD'\}/i" ../c_s.conf

docker volume rm docker_dbdata

docker-compose up -d

sleep 2

echo "password is 'qwer'"
docker-compose exec pg bash -c "runuser -u postgres -- createuser -P cs ; sleep 2 ; runuser -u postgres -- createdb -O cs cs"

docker-compose exec -d cs bash -c "script/cs init_db; sleep 2; script/cs manager & sleep 2; script/cs flags & sleep 2; script/cs minion worker -j 3 & sleep 2 ; script/cs minion worker -q checker -j 48 & sleep 2; hypnotoad script/cs ; sleep 1; hypnotoad script/cs; tail -f /dev/null"
