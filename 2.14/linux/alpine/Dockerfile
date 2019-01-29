FROM matejak/argbash:2.7.1-1 as commands
ADD "https://raw.githubusercontent.com/oconnormi/dev-tools/master/templates/ddf-create-cdm.m4" /work/create-cdm.m4
COPY argbash-templates/* /work/
RUN ./build.sh


# Test Phase
FROM bats/bats as bats
ENV ENTRYPOINT_HOME=/opt/entrypoint

RUN mkdir -p $ENTRYPOINT_HOME

RUN apk add --no-cache curl openssl gettext bash \
    && curl -L https://github.com/oconnormi/props/releases/download/v0.2.0/props_linux_amd64 -o /usr/local/bin/props \
    && chmod 755 /usr/local/bin/props \
    && curl -LsSk https://github.com/stedolan/jq/releases/download/jq-1.5/jq-linux64 -o /usr/local/bin/jq \
    && chmod 755 /usr/local/bin/jq

COPY entrypoint/* $ENTRYPOINT_HOME/
COPY --from=commands /out/cmd/* /usr/local/bin/

# Test argbash based commands
FROM bats as test
COPY argbash-templates/tests /tests/
RUN bats /tests/*.bats

# Test entrypoint scripts
FROM bats as integration_test

COPY tests/* /tests/
RUN bats /tests/*.bats

# End Test Phase


FROM anapsix/alpine-java:8_jdk
MAINTAINER oconnormi

ENV ENTRYPOINT_HOME=/opt/entrypoint

RUN mkdir -p $ENTRYPOINT_HOME

RUN apk add --no-cache curl openssl gettext \
    && curl -L https://github.com/oconnormi/props/releases/download/v0.2.0/props_linux_amd64 -o /usr/local/bin/props \
    && chmod 755 /usr/local/bin/props \
    && curl -LsSk https://github.com/stedolan/jq/releases/download/jq-1.5/jq-linux64 -o /usr/local/bin/jq \
    && chmod 755 /usr/local/bin/jq

COPY entrypoint/* $ENTRYPOINT_HOME/
COPY --from=commands /out/cmd/* /usr/local/bin/

ENTRYPOINT ["/bin/bash", "-c", "$ENTRYPOINT_HOME/entrypoint.sh"]
