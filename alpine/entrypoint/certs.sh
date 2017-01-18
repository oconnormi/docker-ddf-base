#!/bin/bash

# Generate certs
# Need to account for both APP_HOSTNAME (for regular operation) and APP_NODENAME (for clustered operation)
if [ -n "$APP_HOSTNAME" ]; then
  _app_hostname=$APP_HOSTNAME
else
  _app_hostname=$(hostname -f)
fi

_keystoreName=$APP_HOME/etc/keystores/serverKeystore.jks
_storepass=changeit
_keytoolOpts="-keystore $_keystoreName -storepass $_storepass -noprompt"
_san=dns:localhost,ip:127.0.0.1
_keyAlias=$_app_hostname

DUMMY_DELETE_OPTS="-delete -alias localhost $_keytoolOpts"

if [ -n "$APP_NODENAME" ]; then
  _san+=,dns:$APP_NODENAME
  _keyAlias=$APP_NODENAME
fi

# Check if already complete
keytool -list -alias $_keyAlias $_keytoolOpts > /dev/null 2>&1
if [ $? -ne 0 ] ; then

  echo "External Hostname: ${_app_hostname}"
  echo "Alternative Names: $_san"
  echo "Updating ${APP_NAME} certificates"

  keytool -list -alias localhost $_keytoolOpts > /dev/null 2>&1
  if [ $? -eq 0 ] ; then
    echo "localhost key found in $_keystoreName, removing"
    keytool $DUMMY_DELETE_OPTS
  fi

  # Generate key
  keytool -genkey \
          -alias $_keyAlias \
          -dname "CN=$_app_hostname, OU=Dev, O=DDF, L=Hursley, S=AZ, C=US" \
          $_keytoolOpts \
          -keypass $_storepass \
          -validity 3650 \
          -ext SAN=$_san

  # Generate CSR
  keytool -certreq \
          -alias $_keyAlias \
          -keyalg rsa \
          $_keytoolOpts \
          -file $APP_HOME/etc/certs/$_keyAlias.csr

  echo "unique_subject = no" > $APP_HOME/etc/certs/demoCA/index.txt.attr
  # Sign request using DDF Demo CA
  pushd $APP_HOME/etc/certs > /dev/null
  openssl ca \
          -batch \
          -config $APP_HOME/etc/certs/openssl-demo.cnf \
          -passin pass:secret \
          -in $APP_HOME/etc/certs/$_keyAlias.csr \
          -out $APP_HOME/etc/certs/demoCA/newcerts/$_keyAlias.cer > /dev/null 2>&1
  popd > /dev/null

  # Import Cert
  keytool -import \
          $_keytoolOpts \
          -file $APP_HOME/etc/certs/demoCA/newcerts/$_keyAlias.cer \
          -alias $_keyAlias
fi
