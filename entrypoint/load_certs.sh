#!/bin/bash

source ${ENTRYPOINT_HOME}/certs_env.sh

_tmp_cert_dir=/tmp/load_certs
_tmp_output_dir=${_tmp_cert_dir}/out
mkdir -p ${_tmp_output_dir}

_tmp_cert=${_tmp_cert_dir}/cert.pem
_tmp_key=${_tmp_cert_dir}/key.pem
_tmp_ca=${_tmp_cert_dir}/ca.pem
_tmp_p12=${_tmp_output_dir}/cert.p12
_tmp_key_pass=${_tmp_cert_dir}/ssl_key_pass
_tmp_chain=${_tmp_cert_dir}/chain.pem

function checkIfAlreadyDone {
  keytool -list -alias "${_keyAlias}" ${_keytoolOpts} > /dev/null 2>&1
  return $?
}

function writeTempCert {
  if [ ! -n "${SSL_CERT}" ]; then
    return 2
  fi

  if [ ! -n "${SSL_KEY}" ]; then
    return 2
  fi

  if [ ! -n "${SSL_CA_BUNDLE}" ]; then
    return 2
  fi

  echo "${SSL_CERT}" > "${_tmp_cert}"
  echo "${SSL_KEY}" > "${_tmp_key}"
  echo "${SSL_CA_BUNDLE}" > "${_tmp_ca}"
  if [ -f ${_tmp_cert} ] && [ -f ${_tmp_key} ] && [ -f ${_tmp_ca} ]; then
    return 0
  else
    return 1
  fi
}

function removeKeyPass {
  echo "${SSL_KEY_PASS}" > "${_tmp_key_pass}"
  openssl rsa -in ${_tmp_key} -out ${_tmp_key} -passin file:${_tmp_key_pass}
}

function makeChain {
  cat ${_tmp_key} ${_tmp_cert} ${_tmp_ca} > ${_tmp_chain}
}

function extractCA {
  openssl pkcs12 \
    -in ${_tmp_p12} \
    -nokeys \
    -cacerts \
    -out ${_tmp_ca} \
    -passin pass:${_storepass} \
    -passout pass:${_storepass} > /dev/null 2>&1
  return $?
}

function createP12 {
  openssl pkcs12 \
          -export \
          -out ${_tmp_p12} \
          -in ${_tmp_chain} \
          -passin pass:${_storepass} \
          -passout pass:${_storepass} > /dev/null 2>&1

  if [ -f ${_tmp_p12} ]; then
    return 0
  else
    return 1
  fi
}

function importP12 {
  # Import Cert
  keytool -importkeystore \
          ${_keytoolOpts} \
          -keypass ${_storepass} \
          -srcstorepass ${_storepass} \
          -srckeystore ${_tmp_p12} > /dev/null 2>&1

  keytool -changealias \
          ${_keytoolOpts} \
          -alias 1 \
          -destalias ${_keyAlias} > /dev/null 2>&1

  keytool -list -alias "${_keyAlias}" ${_keytoolOpts} > /dev/null 2>&1
  return $?
}

function importTrust {
  keytool -importcert ${_keytoolOpts} -trustcacerts -alias rootCA -file ${_tmp_ca} > /dev/null 2>&1
  local _import_keystore_trust_success=$?
  keytool -importcert ${_trustStoreOpts} -trustcacerts -alias rootCA -file ${_tmp_ca} > /dev/null 2>&1
  local _import_truststore_trust_success=$?
  if [ "${_import_keystore_trust_success}" -eq 0 ] && [ "${_import_truststore_trust_success}" -eq 0 ]; then
    return 0
  else
    return 1
  fi
}

function deleteOldTrust {
  keytool -list -alias "ddf demo root ca" ${_trustStoreOpts} > /dev/null 2>&1
  if [ $? -ne 0 ]; then
    keytool -delete -alias "ddf demo root ca" ${_trustStoreOpts} > /dev/null 2>&1
    if [ $? -ne 0 ]; then
      return 1
    fi
  fi

  keytool -list -alias "ddf demo root ca" ${_keytoolOpts} > /dev/null 2>&1
  if [ $? -ne 0 ]; then
    keytool -delete -alias "ddf demo root ca" ${_keytoolOpts} > /dev/null 2>&1
    if [ $? -ne 0 ]; then
      return 2
    fi
  fi

  return 0
}

function main {
  echo "Preparing to import provided cert from 'SSL_CERT'"
  checkIfAlreadyDone
  if [ $? -eq 0 ]; then
    echo "Certificate for ${_system_internal_hostname} already present in ${_server_keystore_file}, skipping import of certs"
    return 0
  fi

  writeTempCert
  if [ $? -ne 0 ]; then
    echo "Could not write temporary cert to ${_tmp_cert}"
    return 1
  fi

  if [ -n "$SSL_KEY_PASS" ]; then
    removeKeyPass
  fi

  makeChain 

  createP12
  if [ $? -ne 0 ]; then
    echo "Unable to create temporary p12 certificate file ${_tmp_p12}"
    return 1
  fi

  importP12
  if [ $? -ne 0 ]; then
    echo "Unable to import certificate chain ${_tmp_p12} into keystore ${_server_keystore_file}"
    return 1
  fi

  extractCA
  if [ $? -ne 0 ]; then
    echo "Unable to split certificate into separate parts"
    return 1
  fi

  deleteOldTrust
  local _deleteTrustStatus=$?
  if [ $_deleteTrustStatus -eq 1 ]; then
    echo "Unable to remove default trusted CA from truststore"
    return 1
  elif [ $_deleteTrustStatus -eq 2 ]; then
    echo "Unable to remove default trusted CA from keystore"
    return 2
  fi

  importTrust
  if [ $? -ne 0 ]; then
    echo "Unable to import new CA into truststore"
    return 1
  fi
  return 0
}

main
exit $?
