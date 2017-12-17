#!/bin/bash

if [ -n "$APP_HOSTNAME" ]; then
  _app_hostname=$APP_HOSTNAME
else
  _app_hostname=$(hostname -f)
fi

_remote_ca=${CA_REMOTE_URL:=""} # Set to host:port for remote CFSSL based CA
_keystoreName=$APP_HOME/etc/keystores/serverKeystore.jks
_trustStoreName=$APP_HOME/etc/keystores/serverTruststore.jks
_storepass=changeit
_trustStoreOpts="-keystore $_trustStoreName -storepass $_storepass -noprompt"
_keytoolOpts="-keystore $_keystoreName -storepass $_storepass -noprompt"
_san=DNS:$_app_hostname,DNS:localhost,IP:127.0.0.1
_keyAlias=$_app_hostname

DUMMY_DELETE_OPTS="-delete -alias localhost $_keytoolOpts"

if [ -n "$APP_NODENAME" ]; then
  echo "'APP_NODENAME' is deprecated, use 'CSR_SAN=<DNS|IP>:<value>,...' in the future"
  _san+=,DNS:$APP_NODENAME
fi

if [ -n "$CSR_SAN" ]; then
  _san+=$CSR_SAN
fi
