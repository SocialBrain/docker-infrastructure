# Image for compiling turtle scripts

FROM       sb/stack-build:7.10
MAINTAINER Ross MacLeod <ross@socialbrainapp.com>

RUN /sbin/gosu stack env HOME=/home/_stack TERM=vt100 stack build --copy-bins turtle aeson aeson-lens lens


