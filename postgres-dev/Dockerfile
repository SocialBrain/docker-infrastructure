FROM       postgres:9.4
MAINTAINER Ross MacLeod <ross@socialbrainapp.com>

RUN apt-get update && apt-get install -y --no-install-recommends ca-certificates curl jq

COPY postgres-dev-init.sh /docker-entrypoint-initdb.d/postgres-dev-init.sh

ENV POSTGRES_USER=swarm \
    POSTGRES_DB=swarm \
    POSTGRES_PASSWORD=swarm \
    VAULT_DEV_DB_USER_SECRET=secret/dev/db/username \
    VAULT_DEV_DB_PASSWORD_SECRET=secret/dev/db/password \
    VAULT_DEV_TOKEN_FILE=/vault-share/root-token

