#! /bin/bash

vault_url="http://$VAULT_PORT_8200_TCP_ADDR:$VAULT_PORT_8200_TCP_PORT/v1"

echo 'create extension pgcrypto;' | psql -U swarm

start="$(date +"%s")"
while ( curl -q "$vault_url/sys/seal-status" | jq -e '(.sealed) == true' ) > /dev/null; do
    now="$(date +"%s")"
    if test "$(($start + 60))" -lt "$now"; then
        echo "$(date) - giving up waiting for vault to come up"
        exit 1
    fi
    echo "$(date) - waiting for vault"
    sleep 1
done
echo "$(date) - vault up"

set -x

while test ! -f "$VAULT_DEV_TOKEN_FILE"; do
    echo "$(date) - $VAULT_DEV_TOKEN_FILE not present - waiting for it"
    sleep 1
done

vault_root_token="$(cat $VAULT_DEV_TOKEN_FILE)"

curl -H "X-Vault-Token: $vault_root_token" -H "Content-Type: application/json" -X POST -d "{ \"value\": \"$POSTGRES_USER\" }"     "$vault_url/$VAULT_DEV_DB_USER_SECRET"
curl -H "X-Vault-Token: $vault_root_token" -H "Content-Type: application/json" -X POST -d "{ \"value\": \"$POSTGRES_PASSWORD\" }" "$vault_url/$VAULT_DEV_DB_PASSWORD_SECRET"
