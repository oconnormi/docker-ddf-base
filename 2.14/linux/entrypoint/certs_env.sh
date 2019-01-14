#!/bin/bash

source ${ENTRYPOINT_HOME}/global_env.sh

_remote_ca=${CA_REMOTE_URL:=""} # Set to host:port for remote CFSSL based CA
_storepass=changeit
_trustStoreOpts="-keystore ${_server_truststore_file} -storepass ${_storepass} -noprompt"
_keytoolOpts="-keystore ${_server_keystore_file} -storepass ${_storepass} -noprompt"
_san=DNS:${_system_internal_hostname},DNS:${_system_external_hostname},DNS:localhost,IP:127.0.0.1
_keyAlias=${_system_external_hostname}

DUMMY_DELETE_OPTS="-delete -alias localhost ${_keytoolOpts}"

if [ -n "$APP_NODENAME" ]; then
  echo "'APP_NODENAME' is deprecated, use 'CSR_SAN=<DNS|IP>:<value>,...' in the future"
  _san+=,DNS:${APP_NODENAME}
fi

if [ -n "$CSR_SAN" ]; then
  _san+=${CSR_SAN}
fi
