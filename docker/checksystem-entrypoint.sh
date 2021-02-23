#!/usr/bin/env sh

sleep 10

if [ "$1" != "noinit" ]; then
	/app/script/cs init_db
	sleep 2
fi

/app/script/cs manager & sleep 2
/app/script/cs minion worker -j 3 & sleep 2
/app/script/cs minion worker -q checker -j 48 & sleep 2

hypnotoad /app/script/cs
if [ "$?" -ne "0" ]; then
	hypnotoad /app/script/cs
fi

tail -f /dev/null
