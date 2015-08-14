FROM       debian:jessie
MAINTAINER Ross MacLeod <ross@socialbrainapp.com>

ENV VAULT_VERSION=0.2.0 \
    VAULT_ARCH=linux_amd64

EXPOSE 8200

RUN mkdir -p /opt/vault/bin /var/opt/vault/audit /var/opt/vault/log /var/opt/vault/data /etc/opt/vault \
 &  gpg --keyserver pool.sks-keyservers.net --recv-keys B42F6819007F00F88E364FD4036A9C25BF357DD4 \
 && apt-get update && apt-get install -y --no-install-recommends ca-certificates curl unzip jq \
 && curl -L -o /sbin/gosu "https://github.com/tianon/gosu/releases/download/1.2/gosu-$(dpkg --print-architecture)" \
 && curl -L -o /sbin/gosu.asc "https://github.com/tianon/gosu/releases/download/1.2/gosu-$(dpkg --print-architecture).asc" \
 && gpg --verbose --verify /sbin/gosu.asc /sbin/gosu  \
 && rm /sbin/gosu.asc \
 && chmod +x /sbin/gosu \
 && curl -L -O https://dl.bintray.com/mitchellh/vault/vault_${VAULT_VERSION}_${VAULT_ARCH}.zip \
 && unzip vault_${VAULT_VERSION}_${VAULT_ARCH}.zip \
 && mv vault /opt/vault/bin/vault \
 && rm -f vault_${VAULT_VERSION}_${VAULT_ARCH}.zip \
 && useradd vault \
 && chown -R vault /var/opt/vault \
# && setcap cap_ipc_lock=+ep /opt/vault/bin/vault \
 && apt-get purge -y --auto-remove unzip

COPY vault.hcl /etc/opt/vault/vault.hcl
COPY vault-entrypoint /opt/vault/bin/vault-entrypoint

ENTRYPOINT ["/opt/vault/bin/vault-entrypoint"]

