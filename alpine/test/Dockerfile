FROM oconnormi/ddf-base:edge

ENV APP_NAME=test
ENV APP_HOME=/opt/test
ENV APP_LOG=/opt/test/data/log/test.log
ENV CA_HOME=$APP_HOME/etc/certs/demoCA

RUN mkdir -p $APP_HOME/data/log \
    && touch $APP_LOG \
    && mkdir -p $APP_HOME/bin \
    && mkdir -p $APP_HOME/etc/certs \
    && mkdir -p $APP_HOME/etc/keystores

RUN apk --no-cache add subversion \
    && svn \
        --trust-server-cert \
        --non-interactive \
        export \
        https://github.com/codice/ddf/trunk/distribution/ddf-common/src/main/resources/etc/certs/demoCA \
        $CA_HOME \
    && apk --no-cache del subversion

ADD https://raw.githubusercontent.com/codice/ddf/master/distribution/ddf-common/src/main/resources/etc/system.properties $APP_HOME/etc/
ADD https://raw.githubusercontent.com/codice/ddf/master/distribution/ddf-common/src/main/resources/etc/users.attributes $APP_HOME/etc/
ADD https://raw.githubusercontent.com/codice/ddf/master/distribution/ddf-common/src/main/resources/etc/users.properties $APP_HOME/etc/
ADD https://github.com/codice/ddf/blob/master/distribution/ddf-common/src/main/resources/etc/keystores/serverKeystore.jks?raw=true $APP_HOME/etc/keystores/
ADD https://github.com/codice/ddf/blob/master/distribution/ddf-common/src/main/resources/etc/keystores/serverTruststore.jks?raw=true $APP_HOME/etc/keystores/

COPY files/bin/start $APP_HOME/bin/
COPY files/bin/client $APP_HOME/bin/
