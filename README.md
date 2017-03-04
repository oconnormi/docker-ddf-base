# DDF Base

Base level docker image containing all dependencies for DDF

## Cross Platform Entrypoint
Cross platform bootstrapping of DDF nodes is a WIP. 
All Bash and Powershell functionality is being ported to groovy in order to support both windows and
\*nix environments with a single codebase

The cross platform version will replace all supported env vars with command line flags

### Current CLI
```bash
usage: entrypoint [options]
Bootstraps DDF Based Systems
 -c,--cluster <clusterName>   Enables clustered mode. Sets cluster name
 -h,--help                    print this message
 -i,--install-config <arg>    Path to json config file for automated
                              installs
 -l,--ldap-host <ldapHost>    Configures ldap connection. Use hostname
                              only (This is currently for testing only)
 -s,--solr-url <solrHost>     Specify the Solr client connection. If using
                              Solr Cloud this will be a comma-separated
                              list of zookeeper `host:port`
    --solr-mode <solrMode>    Choose Solr client mode. Options are: [http
                              (default), cloud]
```

### Tasks

- [X] Create tests covering pre-start configuration processes
- [ ] Create tests covering post-start configuration processes
- [ ] Replace pre-start shell script implementation
- [ ] Replace certs shell script with ddf cert generator once SAN certificate generation is supported
- [ ] Replace post-start shell script implementation
- [ ] Create docker image for linux
- [ ] Create docker image for windows

# Legacy Bash and Powershell version info
All details below relate to the original functionality provided by the bash and ps1 scripts

## Features

* Oracle JDK 8
* Common Entrypoint for all ddf based applications
  * Customize by adding scripts to `$ENTRYPOINT_HOME/pre/` and `$ENTRYPOINT_HOME/post/`
  * Runtime customization by mounting scripts to `$ENTRYPOINT_HOME/pre_start_custom.sh` and `$ENTRYPOINT_HOME/post_start_custom.sh`
  * Supports setting External hostname via setting `APP_HOSTNAME=<external_hostname>`
    * Generates keystores
    * Adds to loopback adaptor
    * updates `$APP_HOME/etc/users.properties`
    * updates `$APP_HOME/etc/users.attributes`
    * updates hostname in `$APP_HOME/etc/system.properties`
  * Supports External solr via `SOLR_URL=<external_solr_url>`
  * Supports Solr Cloud via `SOLR_ZK_HOSTS=<zookeeper_hosts_list>`
  * Supports external ldap via `LDAP_HOST=<hostname>`
  * Supports Clustering via `APP_NODENAME=<node_name>`
    * NodeName is used to identify the node within the cluster, useful for loadbalancing
  * Feature installation via `INSTALL_FEATURES=<feature1>;<feature2>;...`
  * Feature uninstallation via `UNINSTALL_FEATURES=<feature1>;<feature2>;...`
  * Startup apps via `STARTUP_APPS=<app1>;<app2>;...`


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
