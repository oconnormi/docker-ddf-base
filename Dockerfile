# Generate commands from argbash templates
FROM matejak/argbash:2.10.0 as argbash
ADD "https://raw.githubusercontent.com/oconnormi/dev-tools/master/templates/ddf-create-cdm.m4" /work/create-cdm.m4
COPY argbash-templates/* /work/
RUN ./build.sh

# Create base for final image
FROM alpine:3.18.4 as base
RUN apk add libstdc++ curl ca-certificates bash java-cacerts unzip openjdk8
ENV JAVA_HOME=/usr/lib/jvm/java-1.8-openjdk
LABEL maintainer=oconnormi
LABEL org.codice.application.type=ddf

ENV ENTRYPOINT_HOME=/opt/entrypoint

RUN mkdir -p $ENTRYPOINT_HOME

RUN apk add --no-cache curl openssl gettext
RUN  curl -L https://github.com/oconnormi/props/releases/download/v0.2.0/props_linux_amd64 -o /usr/local/bin/props \
    && chmod 755 /usr/local/bin/props
RUN curl -LsSk https://github.com/stedolan/jq/releases/download/jq-1.5/jq-linux64 -o /usr/local/bin/jq \
    && chmod 755 /usr/local/bin/jq

COPY entrypoint/* $ENTRYPOINT_HOME/
COPY --from=argbash /out/cmd/* /usr/local/bin/

# Create test base
FROM base as test
RUN apk add --no-cache git
RUN git clone https://github.com/bats-core/bats-core.git
RUN ./bats-core/install.sh /usr/local

# Run unit level tests
FROM test as unit-test
COPY ./argbash-templates/tests/* /tests/
RUN bats /tests/*.bats

# Run integration level tests
FROM test as integration-test
COPY ./tests/* /tests/
RUN bats /tests/*.bats

# Create final image
FROM base

ENTRYPOINT ["/bin/bash", "-c", "$ENTRYPOINT_HOME/entrypoint.sh"]
