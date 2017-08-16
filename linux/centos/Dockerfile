FROM centos:centos7
MAINTAINER oconnormi

# Environment Variables
# JAVA Environment Variables
ENV JDK_VERSION=8u131
ENV JDK_BUILD_VERSION=b11
ENV JAVA_HOME /usr/java/latest
# DDF Environment Variables
ENV ENTRYPOINT_HOME=/opt/entrypoint
ENV APP_CONFIG=/config
ENV APP_DATA=/data
ENV APP_DEPLOY=/deploy
ENV KARAF_ETC=$APP_CONFIG
ENV KARAF_DATA=$APP_DATA
ENV KARAF_DEPLOY=$APP_DEPLOY

# Update OS with necessary packages
RUN yum update -y \
    && yum install -y unzip \
    && yum install -y openssl

# Download Oracle Java
RUN curl -OL "http://download.oracle.com/otn-pub/java/jdk/$JDK_VERSION-$JDK_BUILD_VERSION/d54c1d3a095b4ff2b6607d096fa80163/jdk-$JDK_VERSION-linux-x64.rpm" -H 'Cookie: oraclelicense=accept-securebackup-cookie' \
    && yum install -y jdk-$JDK_VERSION-linux-x64.rpm \
    && yum clean all \
    && rm -f jdk-$JDK_VERSION-linux-x64.rpm

# Stage Entrypoint scripts
RUN mkdir -p $ENTRYPOINT_HOME
COPY entrypoint/* $ENTRYPOINT_HOME/

RUN curl -L https://github.com/oconnormi/props/releases/download/v0.2.0/props_linux_386 -o /usr/local/bin/props \
    && chmod 755 /usr/local/bin/props

ENTRYPOINT ["/bin/bash", "-c", "$ENTRYPOINT_HOME/entrypoint.sh"]
