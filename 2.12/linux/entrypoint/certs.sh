#!/bin/bash

# Generate certs
source $ENTRYPOINT_HOME/certs_env.sh

# Check if already complete
keytool -list -alias $_keyAlias $_keytoolOpts > /dev/null 2>&1
if [ $? -ne 0 ] ; then

  keytool -list -alias localhost $_keytoolOpts > /dev/null 2>&1
  if [ $? -eq 0 ] ; then
    echo "localhost key found in $_keystoreName, removing"
    keytool $DUMMY_DELETE_OPTS
  fi

  if [ -n "${_remote_ca}" ]; then
    $ENTRYPOINT_HOME/remote_ca_request.sh
  else
    $ENTRYPOINT_HOME/local_ca_request.sh
  fi
fi
