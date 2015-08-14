# Image for building swarm, including the prerequisites such as postgres

FROM       sb/stack-build:7.10
MAINTAINER Ross MacLeod <ross@socialbrainapp.com>

ENV PG_MAJOR 9.4
ENV PG_VERSION 9.4.4-1.pgdg80+1

RUN apt-key adv --keyserver ha.pool.sks-keyservers.net --recv-keys B97B0AFCAA1A47F044F244A07FCC7D46ACCC4CF8 \
 && ( echo 'deb http://apt.postgresql.org/pub/repos/apt/ jessie-pgdg main' $PG_MAJOR > /etc/apt/sources.list.d/pgdg.list ) \
 && apt-get update \
 && apt-get install -y --no-install-recommends libpq-dev

