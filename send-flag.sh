#!/usr/bin/env sh

TOKEN=""
FLAG=$1

curl --header "Content-Type: application/json" \
	--header "X-Team-Token: $TOKEN" \
	--request PUT --data "[\"$FLAG\"]" \
	http://10.0.0.1:8080/flags
