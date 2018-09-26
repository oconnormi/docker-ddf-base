FROM matejak/argbash

COPY argbash-templates/* /work/
ADD "https://raw.githubusercontent.com/oconnormi/dev-tools/master/templates/ddf-create-cdm.m4" /work/create-cdm.m4
RUN ./build.sh

FROM centos:centos7
MAINTAINER oconnormi

# Environment Variables
# JAVA Environment Variables
ENV JDK_VERSION=8u181 \
    JDK_BUILD_VERSION=b13 \
    JDK_ID=96a7b8442fe848ef90c96a2fad6ed6d1 \
    JAVA_HOME=/usr/java/latest \
    ENTRYPOINT_HOME=/opt/entrypoint

# Update OS with necessary packages
RUN yum update -y \
    && yum install -y unzip openssl

# Download Oracle Java
RUN curl -OL "http://download.oracle.com/otn-pub/java/jdk/$JDK_VERSION-$JDK_BUILD_VERSION/$JDK_ID/jdk-$JDK_VERSION-linux-x64.rpm" -H 'Cookie: oraclelicense=accept-securebackup-cookie' \
    && yum install -y jdk-$JDK_VERSION-linux-x64.rpm \
    && yum clean all \
    && rm -f jdk-$JDK_VERSION-linux-x64.rpm \
    && curl -LsSk https://github.com/stedolan/jq/releases/download/jq-1.5/jq-linux64 -o /usr/local/bin/jq \
    && chmod 755 /usr/local/bin/jq

# Stage Entrypoint scripts
RUN mkdir -p $ENTRYPOINT_HOME
COPY entrypoint/* $ENTRYPOINT_HOME/
COPY --from=0 /out/cmd/* /usr/local/bin/

RUN curl -L https://github.com/oconnormi/props/releases/download/v0.2.0/props_linux_386 -o /usr/local/bin/props \
    && chmod 755 /usr/local/bin/props

ENTRYPOINT ["/bin/bash", "-c", "$ENTRYPOINT_HOME/entrypoint.sh"]
