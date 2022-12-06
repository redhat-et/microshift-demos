#!/bin/bash

ACCESS_TOKEN_FILE=$HOME/.rh_access_token
OFFLINE_TOKEN=eyJhbGciOiJIUzI1NiIsInR5cCIgOiAiSldUIiwia2lkIiA6ICJhZDUyMjdhMy1iY2ZkLTRjZjAtYTdiNi0zOTk4MzVhMDg1NjYifQ.eyJpYXQiOjE2NjUwOTIwMzAsImp0aSI6IjU1NTM3NmQ5LTU4YmEtNGQwMS1iNzhiLTE0MDkzYzE0YzYwOCIsImlzcyI6Imh0dHBzOi8vc3NvLnJlZGhhdC5jb20vYXV0aC9yZWFsbXMvcmVkaGF0LWV4dGVybmFsIiwiYXVkIjoiaHR0cHM6Ly9zc28ucmVkaGF0LmNvbS9hdXRoL3JlYWxtcy9yZWRoYXQtZXh0ZXJuYWwiLCJzdWIiOiJmOjUyOGQ3NmZmLWY3MDgtNDNlZC04Y2Q1LWZlMTZmNGZlMGNlNjpmemRhcnNreUByZWRoYXQuY29tIiwidHlwIjoiT2ZmbGluZSIsImF6cCI6InJoc20tYXBpIiwic2Vzc2lvbl9zdGF0ZSI6IjBkMjUxYzgxLWM4NTktNGQyMi04YTM5LTQ2NjY3Mzc0ZTFhOCIsInNjb3BlIjoib2ZmbGluZV9hY2Nlc3MiLCJzaWQiOiIwZDI1MWM4MS1jODU5LTRkMjItOGEzOS00NjY2NzM3NGUxYTgifQ.FZAEPh45CSlEjzFFRU_yIuC7R1-gHosQlHF8u27HC0A

title() {
    echo -e "\E[34m# $1\E[00m";
}

#if [ ! -f "${ACCESS_TOKEN_FILE}" ]; then
    title "Requesting a new access token"
    curl --silent \
        --request POST \
        --data grant_type=refresh_token \
        --data client_id=rhsm-api \
        --data refresh_token="${OFFLINE_TOKEN}" \
        "https://sso.redhat.com/auth/realms/redhat-external/protocol/openid-connect/token" \
        | jq -r .access_token \
        > "${ACCESS_TOKEN_FILE}"
#fi
access_token=$(<"${ACCESS_TOKEN_FILE}")

# title "Fetching prod OpenAPI spec"
# curl --silent \
#     --header "Authorization: Bearer $access_token" \
#     https://console.redhat.com/api/image-builder/v1/openapi.json \
#   | jq . > prod_api.json

title "Fetching staging OpenAPI spec"
curl --silent \
    --header "Authorization: Bearer $access_token" \
    --proxy "http://squid.corp.redhat.com:3128" \
    "https://console.stage.redhat.com/api/image-builder/v1/openapi.json"
