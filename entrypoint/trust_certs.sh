#!/bin/bash

source ${ENTRYPOINT_HOME}/global_env.sh
source ${ENTRYPOINT_HOME}/certs_env.sh

_trusted_certs_dir="/trusted_certs"

function importTrustStore {
  echo "Importing cert: ${1} into trust store"
  keytool -importcert ${_trustStoreOpts} -trustcacerts -alias ${1%.*} -file ${_trusted_cers_dir}/${1} > /dev/null
  return $?       
}

function importKeyStore {
  echo "Importing cert: ${1} into key store"
  keytool -importcert ${_keytoolOpts} -trustcacerts -alias ${1%.*} -file ${_trusted_cers_dir}/${1} > /dev/null
  return $?       
}

function import {
  if [ -d "${_trusted_certs_dir}" ]; then
    for cert in ${_trusted_certs_dir}/*.pem; do
      importTrustStore ${cert}
      if [ $? -ne 0 ]; then
        return 1
      fi
      importKeyStore ${cert}
      if [ $? -ne 0 ]; then
        return 2
      fi
    done
  fi
  return 0
}

import
exit $?
