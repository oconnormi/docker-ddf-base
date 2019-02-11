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
FROM codice/ddf-base

ENV APP_NAME=<app_name>
ENV APP_HOME=<app_home>
ENV APP_LOG=<log_file>
...
# Install application
```
## Features
  * Oracle JDK8
  * [jq](https://stedolan.github.io/jq/) for processing json
  * curl
  * [props](https://github.com/oconnormi/props) tool for modifying properties files
  * Common entry point for DDF based distributions
  * Automated certificate generation
  * Automated initial setup and configuration
    * Can request certs from a remote cfssl based CA via `CA_REMOTE_URL=https://<host>:<port>`  

## Extending

All the steps performed by the scripts in this image are broken down into two categories, `pre-start` and `post-start`.
Pre-start steps are all performed prior to the ddf instance being started, while post-start steps are all performed after the ddf instance is started.

Both of these sets of steps can be extended easily using the following methods.

### Customizing Readiness Check

There are a few protections in place in this image to help get timings right when performing installations. The default approach checks if all bundles are started before considering the system "ready"
By default there are a few bundles that are excluded from this check. These defaults can be overriden via the `READINESS_EXCLUSIONS` environment variable

The default exclusions are: `Apache Karaf :: Features :: Extension, Hosts|DDF :: Platform :: OSGi :: Conditions, Hosts|Apache Karaf :: Shell :: Console, Hosts|DDF :: Platform :: PaxWeb :: Jetty Config, Hosts`
Exclusions must be a string that is separated by `|` characters for each entry
Downstream images that need a custom set of exclusions should override via their `Dockerfile`:

```Dockerfile
...
ENV READINESS_EXCLUSIONS="some bundle name|another bundle name|yet another bundle name"
...
```

Additionally for distributions that make use of the fabric8 health/readiness endpoint the experimental health checks can be used instead of the older approach by setting `EXPERIMENTAL_READINESS_CHECKS_ENABLED=true`
*Note:* This requires that the `fabric8-karaf-checks` feature is installed as part of the distribution's boot features

### Pre-Start Extensions

For simple extension, add a script: `$ENTRYPOINT_HOME/pre_start_custom.sh`
For more complex extension, any number of executable files can be added to `$ENTRYPOINT_HOME/pre/`

### Post-Start Extensions

For simple extension, add a script: `$ENTRYPOINT_HOME/post_start_custom.sh`
For more complex extension, any number of executable files can be added to `$ENTRYPOINT_HOME/post/`

### Basic Configuration

#### System Hostname

To set the external hostname used by DDF based systems, provide a value to `EXTERNAL_HOSTNAME=<hostname>`. This will be the hostname that all external requests to the system should use.

To set the internal hostname used by DDF based systems, provide a value to `INTERNAL_HOSTNAME=<hostname>`

#### Internal System Ports

*Note:* Setting these options changes the ports that are actually bound by the server. In most cases this should not be necessary.

To set the internal HTTPS Port provide a value for `INTERNAL_HTTPS_PORT=<port>`

To set the internal HTTP Port provide a value for `INTERNAL_HTTP_PORT=<port>`

#### External System Ports

*Note:* Setting these options affect the url that the server expects external requests to use.

To set the external HTTPS Port provide a value for `EXTERNAL_HTTPS_PORT=<port>`

To set the external HTTP Port provide a value for `EXTERNAL_HTTP_PORT=<port>`

#### External Solr

To configure a solr backend, provide a value to `SOLR_URL=<external solr url>`. By default this will use the internal solr server

To configure a solr cloud backend, provide a value to `SOLR_ZK_HOSTS=<zk host>,<zk host>,<zk host>,...`
#### External LDAP

To configure the ldap client, provide a value to `LDAP_HOST=<hostname>`. *NOTE:* Currently this is for testing purposes only, as it does not provide a means for configuring the protocol, port, username, or password used by the ldap client.

#### Java Memory

To set the amount of memory allocated to the system set `JAVA_MAX_MEM`

#### Advanced Configuration

Copy (or mount) any necessary configuration files into `APP_HOME/etc/`

Additionally any files mounted or copied to `$ENTRYPOINT_HOME/pre_config` will be copied under `APP_HOME` before the system is started

### Managing Apps and Features

There are several methods for installing and uninstalling apps and features at startup.

To use an install profile, provide a profile name to `INSTALL_PROFILE=<profile name>` this can be used to install any profiles registered with the installer, as well as custom json based profiles located under `APP_HOME/etc/profiles/`
This method supports installing/uninstalling apps, features, and bundles.

To install features, provide a list of features to `INSTALL_FEATURES=<feature name>;<feature name>;...`

To uninstall features, provide a list of features to `UNINSTALL_FEATURES=<feature name>;<feature name>;...`

To start apps, provide a list of apps to `STARTUP_APPS=<app name>;<app name>;...`

### Configuring HTTPS

Custom keystores can easily be mounted to `APP_HOME/etc/keystores/serverKeystore.jks` and `APP_HOME/etc/keystores/serverTruststore.jks`

#### Auto-generated demo certs

If custom keystores are not used the startup process will generate certificates on the fly. By default the local ddf demo CA (bundled within the ddf distribution) will be used to generate a certificate for the value of `INTERNAL_HOSTNAME`, or if not provided the value of `hostname -f` will be used.

Additionally Subject Alternative Names will be added to the certificate for `DNS:$INTERNAL_HOSTNAME(if unset will use `hostname -f`),$EXTERNAL_HOSTNAME,DNS:localhost,IP:127.0.0.1`.
To add additional SAN values use the `CSR_SAN=<DNS|IP>:<value>,...` environment variable.

#### Import Existing Certificates

Certificates can be imported at runtime by passing the certificate chain in the `SSL_CERT` environment variable. The chain must be in the format:

```
-----BEGIN RSA PRIVATE KEY-----
<KEY>
-----END RSA PRIVATE KEY-----
-----BEGIN CERTIFICATE-----
<CERT>
-----END CERTIFICATE-----
-----BEGIN CERTIFICATE-----
<CA_CERT>
-----END CERTIFICATE-----
```

*Warning:* This should not be used in a production environment as it is insecure. Anyone with access to the docker daemon will be able to retrieve this from the environment.

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

### Seeding Data

It is possible to automatically seed the system with data using multiple methods. Both catalog metadata and content can be preloaded from local and remote sources. This is mostly useful for testing and demonstration purposes.

#### Seeding Catalog Metadata

To ingest data automatically after the system is running, the `INGEST_DATA` environment variable can be used.
It can take a comma separated list of locations to retrieve archives of metadata from: `https://foo.bar/baz.zip,http://fake.com/foo.tar.gz`
Supported archive types are:
- `zip`
- `tar`
- `tar.gz`
- `tgz`

Supported protocols are:
- `http://`
- `https://`
- `file://`

Optionally a transformer for each set of data can be specified by adding `|<transformerName>` after each item in the list

Full Example:
`INGEST_DATA=https://foo.bar/baz.zip|xml,http://fake.com/foo.tar.gz|geojson,file:///some/local/file.zip`

#### Seeding Content Data

To pre-load and index content automatically after the sytem is running, the `SEED_CONTENT` environment variable can be used.
It can take a comma separated list of locations to retrieve archives of data (these can include mixed types of data): `https://foo.bar/data.zip,http:fake.com/moreData.tar.gz`

Supported archive types are:
- `zip`
- `tar`
- `tar.gz`
- `tgz`

Supported protocols are:
- `http://`
- `https://`
- `file://`

Full Example:
`SEED_CONTENT=https://foo.bar/data.zip,file:///some/directory/moreData.tar.gz`


### Configuring Content Directory Monitors

Content directory monitor can be used to watch a directory for files to be stored and indexed. It is possible to create an arbitrary number of monitored directories using the `CDM` environment variable.

The `CDM` environment variable supports specifying all properties for each CDM instance like `<directory>|<processing_mechanism>|<threads>|<readlock>` where `<directory>` is the only required parameter.

Full example:
`CDM=/monitor|in_place|1|500,/foo|delete|1|200,/bar`

### Configuring IdP Client

To configure the IdP client metadata location set the `IDP_URL` environment variable. For example: `IDP_URL=https://some.host/services/idp/login/metadata`

### Configuring Registries

Multiple registries containing federated source listings can be used to automatically set up federation.
To configure registries set the `REGISTRY` environment variable.
The registry variable takes input in the form `REGISTRY=url|option|option|...,url|option|...

The only required argument for each registry is the url. Other positional options are as follows:

| Parameter    | Description                                                         | Default                          |
|:------------:|:-------------------------------------------------------------------:|:--------------------------------:|
| `name`       | Sets the name of the remote registry                                | Defaults to the URL when omitted |
| `type`       | Sets the registry type                                              | `csw`                            |
| `push`       | Configures registry client to push to registry                      | `true`                           |
| `pull`       | Configures registry client to pull from registry                    | `true`                           |
| `auto-push`  | Configures registry client to push its identity to the registry     | `true`                           |
| `username`   | Configures registry client username                                 | `null`                           |
| `password`   | Configures registry client password                                 | `null`                           |

#### Extending

By default the base image only supports `CSW` type registries.
To support other registry types add a template to `$ENTRYPOINT_HOME/templates/registry/`.
Templates should be named: `<name>.template`

### Troubleshooting

Sometimes during the startup process the system can take a while to fully initialize. This can be due to memory/cpu constraints. On underpowered systems it might be necessary to instruct the entrypoint script to wait longer and attempt more retries to connect to the system during the boot process. This can be accomplished by setting the `KARAF_CLIENT_DELAY=<time> (default: 10)` (in seconds) or `KARAF_CLIENT_RETRIES=<number> (default: 12)`

## Deprecated features
* `APP_NODENAME=<node_name>` *DEPRECATED* use `CSR_SAN=<DNS|IP>:<value>,...` instead
* `APP_HOSTNAME=<hostname>` *DEPRECATED* use `INTERNAL_HOSTNAME=<hostname>` instead
