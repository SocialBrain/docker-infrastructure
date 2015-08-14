# Base image for developing with Stack and GHC 7.10.2, used as a base for the various build layers.

# Derived from https://github.com/commercialhaskell/stack/blob/master/etc/docker/haskell-stack/Dockerfile
# but using nightly resolver and GHC 7.10.2

FROM       debian:jessie
MAINTAINER Ross MacLeod <ross@socialbrainapp.com>

# Use gosu instead of sudo but simple
RUN gpg --keyserver pool.sks-keyservers.net --recv-keys B42F6819007F00F88E364FD4036A9C25BF357DD4 \
 && apt-get update && apt-get install -y --no-install-recommends ca-certificates curl && rm -rf /var/lib/apt/lists/* \
 && curl -L -o /sbin/gosu "https://github.com/tianon/gosu/releases/download/1.2/gosu-$(dpkg --print-architecture)" \
 && curl -L -o /sbin/gosu.asc "https://github.com/tianon/gosu/releases/download/1.2/gosu-$(dpkg --print-architecture).asc" \
 && gpg --verbose --verify /sbin/gosu.asc /sbin/gosu  \
 && rm /sbin/gosu.asc \
 && chmod +x /sbin/gosu \
 && apt-get purge -y --auto-remove ca-certificates curl

RUN echo 'deb http://download.fpcomplete.com/debian/jessie stable main' > /etc/apt/sources.list.d/fpco.list \
 && apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 575159689BEFB442 \
 && apt-get update      \
 && apt-get install -y  \
        ca-certificates \
        git             \
        libssl-dev      \
        stack           \
        python3         \
# sudo            \
 && apt-get clean

ENV MY_INIT_ARGS="--skip-startup-files --skip-runit --quiet"
COPY my_init /sbin/my_init
RUN useradd -d /home/_stack -u 4444 -c Docker -m stack \
 && mkdir -p /home/_stack/.stack/global \
 && mkdir -p /etc/container_environment
COPY stack.yaml /home/_stack/.stack/global/stack.yaml
COPY container_environment/* /etc/container_environment/
RUN chmod +x /sbin/my_init \
 && chown -R stack:stack /home/_stack \
 && /sbin/gosu stack env HOME=/home/_stack TERM=vt100 stack setup --upgrade-cabal \
 && /sbin/gosu stack env HOME=/home/_stack TERM=vt100 stack install cabal-install \
 && cd /usr/bin \
 && for I in /home/_stack/.stack/programs/x86_64-linux/ghc-7.10.2/bin/* \
             /home/_stack/.stack/snapshots/x86_64-linux/ghc-7.10.2/bin/*; do ln -s $I; done
COPY entrypoint.sh /root/entrypoint.sh

ENTRYPOINT ["/root/entrypoint.sh"]
CMD ["bash"]
