FROM centos:centos7
MAINTAINER oconnormi

# Environment Variables
# JAVA Environment Variables
ENV JDK_VERSION=8u171 \
    JDK_BUILD_VERSION=b11 \
    JAVA_HOME=/usr/java/latest \
    ENTRYPOINT_HOME=/opt/entrypoint

# Update OS with necessary packages
RUN yum update -y \
    && yum install -y unzip openssl

# Download Oracle Java
RUN curl -OL "http://download.oracle.com/otn-pub/java/jdk/$JDK_VERSION-$JDK_BUILD_VERSION/512cd62ec5174c3487ac17c61aaa89e8/jdk-$JDK_VERSION-linux-x64.rpm" -H 'Cookie: oraclelicense=accept-securebackup-cookie' \
    && yum install -y jdk-$JDK_VERSION-linux-x64.rpm \
    && yum clean all \
    && rm -f jdk-$JDK_VERSION-linux-x64.rpm \
    && curl -LsSk https://github.com/stedolan/jq/releases/download/jq-1.5/jq-linux64 -o /usr/local/bin/jq \
    && chmod 755 /usr/local/bin/jq

# Stage Entrypoint scripts
RUN mkdir -p $ENTRYPOINT_HOME
COPY entrypoint/* $ENTRYPOINT_HOME/

RUN curl -L https://github.com/oconnormi/props/releases/download/v0.2.0/props_linux_386 -o /usr/local/bin/props \
    && chmod 755 /usr/local/bin/props

ENTRYPOINT ["/bin/bash", "-c", "$ENTRYPOINT_HOME/entrypoint.sh"]
