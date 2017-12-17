# DDF Base

Base level docker image containing all dependencies for DDF as well as a common set of steps for running a DDF based distribution

## Usage Requirements

This image is meant to be the basis for any ddf based image.
It packages the dependencies and an entrypoint script for use with any ddf based application

Any downstream containers must provide environment variables for:

* APP_NAME - Name of application, used for branding by the entrypoint
* APP_HOME - Home Directory for application installation (should have a bin directory as a child)
* APP_LOG - Location of the application log file

```Dockerfile
FROM oconnormi/ddf-base

ENV APP_NAME=<app_name>
ENV APP_HOME=<app_home>
ENV APP_LOG=<log_file>
...
# Install application
```

## Extending

All the steps performed by the scripts in this image are broken down into two categories, `pre-start` and `post-start`.
Pre-start steps are all performed prior to the ddf instance being started, while post-start steps are all performed after the ddf instance is started.

Both of these sets of steps can be extended easily using the following methods.

### Pre-Start Extensions

For simple extension, add a script: `$ENTRYPOINT_HOME/pre_start_custom.sh`
For more complex extension, any number of executable files can be added to `$ENTRYPOINT_HOME/pre/`

### Post-Start Extensions

For simple extension, add a script: `$ENTRYPOINT_HOME/post_start_custom.sh`
For more complex extension, any number of executable files can be added to `$ENTRYPOINT_HOME/post/`

## Features
  * Oracle JDK8
  * [jq](https://stedolan.github.io/jq/) for processing json
  * curl
  * [props](https://github.com/oconnormi/props) tool for modifying properties files
  * Common entry point for DDF based distributions
  * Automated certificate generation
  * Automated initial setup and configuration

### Basic Configuration

To set the hostname used by DDF based systems, provide a value to `APP_HOSTNAME=<hostname>`

To configure a solr backend, provide a value to `SOLR_URL=<external solr url>`. By default this will use the internal solr server

To configure a solr cloud backend, provide a value to `SOLR_ZK_HOSTS=<zk host>,<zk host>,<zk host>,...`

To configure the ldap client, provide a value to `LDAP_HOST=<hostname>`. *NOTE:* Currently this is for testing purposes only, as it does not provide a means for configuring the protocol, port, username, or password used by the ldap client.

#### Advanced Configuration

Copy (or mount) any necessary configuration files into `APP_HOME/etc/`

### Managing Apps and Features

There are several methods for installing and uninstalling apps and features at startup.

To install features, provide a list of features to `INSTALL_FEATURES=<feature name>;<feature name>;...`

To uninstall features, provide a list of features to `UNINSTALL_FEATURES=<feature name>;<feature name>;...`

To start apps, provide a list of apps to `STARTUP_APPS=<app name>;<app name>;...`

### Configuring HTTPS

Custom keystores can easily be mounted to `APP_HOME/etc/keystores/serverKeystore.jks` and `APP_HOME/etc/keystores/serverTruststore.jks`

#### Auto-generated demo certs

If custom keystores are not used the startup process will generate certificates on the fly. By default the local ddf demo CA (bundled within the ddf distribution) will be used to generate a certificate for the value of `APP_HOSTNAME`, or if not provided the value of `hostname -f` will be used.

Additionally Subject Alternative Names will be added to the certificate for `DNS:$APP_HOSTNAME(if unset will use `hostname -f`),DNS:localhost,IP:127.0.0.1`.
To add additional SAN values use the `CSR_SAN=<DNS|IP>:<value>,...` environment variable.

#### Remote CA Support

Certificates can also be requested from a remote [cffsl](https://github.com/cloudflare/cfssl) based CA at startup by using the `REMOTE_CA_URL=https://<host>:<port>`. By default this will request a certificate from the remote CA that looks identical to the ones generated from the local CA. The remote CA mode provides additional configuration options for customizing the values used in the certificate.

##### CSR Customization

Only applicable when using `CA_REMOTE_URL`

| Variable                  | Description                                                      | Default                        |
|:-------------------------:|:----------------------------------------------------------------:|:------------------------------:|
| `CSR_KEY_ALGORITHM`       | Sets the key algorithm for the generated Certificate             | `rsa`                          |
| `CSR_KEY_SIZE`            | Sets the key size for the generated Certificate                  | `2048`                         |
| `CSR_SAN`                 | Sets the SAN value for the generated Certificate                 | `DNS:<hostname>,DNS:localhost` |
| `CSR_COUNTRY`             | Sets the Country value for the generated Certificate             | `US`                           |
| `CSR_LOCALITY`            | Sets the Locality value for the generated Certificate            | `Hursley`                      |
| `CSR_ORGANIZATION`        | Sets the Organization value for the generated Certificate        | `DDF`                          |
| `CSR_ORGANIZATIONAL_UNIT` | Sets the Organizational Unit value for the generated Certificate | `Dev`                          |
| `CSR_STATE`               | Sets the State value for the generated Certificate               | `AZ`                           |
| `CSR_PROFILE`             | Sets the type of certificate requested from the CA               | `server`                       |


## Deprecated features
* `APP_NODENAME=<node_name>` *DEPRECATED* use `CSR_SAN=<DNS|IP>:<value>,...` instead
