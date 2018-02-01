FROM anapsix/alpine-java:8_jdk
MAINTAINER oconnormi

ENV ENTRYPOINT_HOME=/opt/entrypoint

RUN mkdir -p $ENTRYPOINT_HOME

COPY entrypoint/* $ENTRYPOINT_HOME/

ENTRYPOINT ["/bin/bash", "-c", "$ENTRYPOINT_HOME/entrypoint.sh"]
