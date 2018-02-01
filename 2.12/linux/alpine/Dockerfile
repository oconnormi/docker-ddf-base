FROM anapsix/alpine-java:8_jdk
MAINTAINER oconnormi

ENV ENTRYPOINT_HOME=/opt/entrypoint

RUN mkdir -p $ENTRYPOINT_HOME

RUN apk add --no-cache curl openssl \
    && curl -L https://github.com/oconnormi/props/releases/download/v0.2.0/props_linux_amd64 -o /usr/local/bin/props \
    && chmod 755 /usr/local/bin/props \
    && curl -LsSk https://github.com/stedolan/jq/releases/download/jq-1.5/jq-linux64 -o /usr/local/bin/jq \
    && chmod 755 /usr/local/bin/jq

COPY entrypoint/* $ENTRYPOINT_HOME/

ENTRYPOINT ["/bin/bash", "-c", "$ENTRYPOINT_HOME/entrypoint.sh"]
