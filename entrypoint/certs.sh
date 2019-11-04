#!/bin/bash

# Generate certs
source $ENTRYPOINT_HOME/certs_env.sh

# Check if already complete
keytool -list -alias $_keyAlias $_keytoolOpts > /dev/null 2>&1
if [ $? -ne 0 ] ; then

  keytool -list -alias localhost $_keytoolOpts > /dev/null 2>&1
  if [ $? -eq 0 ] ; then
    echo "localhost key found in $_server_keystore_file, removing"
    keytool $DUMMY_DELETE_OPTS
  fi

  if [ -n "${SSL_CERT}" ]; then
    $ENTRYPOINT_HOME/load_certs.sh
  elif [ -n "${_remote_ca}" ]; then
    $ENTRYPOINT_HOME/remote_ca_request.sh
  else
    $ENTRYPOINT_HOME/local_ca_request.sh
  fi
fi

_cn_filter=".*$(keytool ${_keytoolOpts} -list -alias ${_system_internal_hostname} -v 2> /dev/null | grep -io CN=.* | head -n 1 | cut -d, -f 1).*"

echo "Updating Security Subject Cert Constraints to ${_cn_filter}"

props set ${_ws_security_subject_constraint} ${_cn_filter} ${_system_properties_file}
