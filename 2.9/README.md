# DDF Base

Base level docker image containing all dependencies for DDF

## Features

* Oracle JDK 8
* Common Entrypoint for all ddf based applications
  * Customize by adding scripts to `$ENTRYPOINT_HOME/pre/` and `$ENTRYPOINT_HOME/post/`
  * Runtime customization by mounting scripts to `$ENTRYPOINT_HOME/pre_start_custom.sh` and `$ENTRYPOINT_HOME/post_start_custom.sh`
  * Supports setting External hostname via setting ``$APP_HOSTNAME=<external_hostname>``
    * Generates keystores
    * Adds to loopback adaptor
    * updates `$APP_HOME/etc/users.properties`
    * updates `$APP_HOME/etc/users.attributes`
    * updates hostname in `$APP_HOME/etc/system.properties`


## Requirements

Any upstream containers must provide environment variables for:

* APP_NAME - Name of application, used for branding by the entrypoint
* APP_HOME - Home Directory for application installation (should have a bin directory as a child)
* APP_LOG - Location of the application log file

## Usage

This image is meant to be the basis for any ddf based image.
It packages the dependencies and an entrypoint script for use with any ddf based application

```Dockerfile
FROM oconnormi/ddf-base

ENV APP_NAME=<app_name>
ENV APP_HOME=<app_home>
ENV APP_LOG=<log_file>
...
# Install application
```
