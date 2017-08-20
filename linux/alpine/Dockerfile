FROM anapsix/alpine-java:jdk
MAINTAINER oconnormi

ENV ENTRYPOINT_HOME=/opt/entrypoint
ENV APP_CONFIG=/config
ENV APP_DATA=/data
ENV APP_DEPLOY=/deploy
ENV KARAF_ETC=$APP_CONFIG
ENV KARAF_DATA=$APP_DATA
ENV KARAF_DEPLOY=$APP_DEPLOY

RUN mkdir -p $ENTRYPOINT_HOME

COPY entrypoint/* $ENTRYPOINT_HOME/

RUN apk add --no-cache curl openssl rsync\
    && curl -L https://github.com/oconnormi/props/releases/download/v0.2.0/props_linux_amd64 -o /usr/local/bin/props \
    && chmod 755 /usr/local/bin/props \
    && apk del --no-cache curl

VOLUME /config /data /deploy
ENTRYPOINT ["/bin/bash", "-c", "$ENTRYPOINT_HOME/entrypoint.sh"]
