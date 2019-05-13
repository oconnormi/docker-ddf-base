#!/bin/bash

source ${ENTRYPOINT_HOME}/certs_env.sh

_tmp_cert_dir=/tmp/load_certs
_tmp_output_dir=${_tmp_cert_dir}/out
mkdir -p ${_tmp_output_dir}

_tmp_cert=${_tmp_cert_dir}/cert.pem
_tmp_p12=${_tmp_output_dir}/cert.p12
_tmp_ca=${_tmp_output_dir}/ca.pem

function checkIfAlreadyDone {
  keytool -list -alias "${_keyAlias}" ${_keytoolOpts} > /dev/null 2>&1
  return $?
}

function writeTempCert {
  if [ ! -n "${SSL_CERT}" ]; then
    return 2
  fi

  echo "${SSL_CERT}" > "${_tmp_cert}"
  if [ -f ${_tmp_cert} ]; then
    return 0
  else
    return 1
  fi
}

function validateCert {
  if [ ! -f ${_tmp_cert} ]; then
    return 2
  fi
  _cert_count=$(cat ${_tmp_cert} | grep 'BEGIN CERTIFICATE' | wc -l)
  _key_count=$(cat ${_tmp_cert} | grep 'BEGIN RSA PRIVATE KEY' | wc -l)
  if [ "${_cert_count}" == "2" ] && [ "${_key_count}" == "1" ]; then
    return 0
  else
    return 1
  fi
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
          -in ${_tmp_cert} \
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

  validateCert
  if [ $? -ne 0 ]; then
    echo -e "Provided certificate didn't meet requirements.\n\t'SSL_CERT must contain (in this order)\n\t\t-----BEGIN RSA PRIVATE KEY-----\n\t\t<KEY>\n\t\t-----END RSA PRIVATE KEY-----\n\t\t-----BEGIN CERTIFICATE-----\n\t\t<CERT>\n\t\t-----END CERTIFICATE-----\n\t\t-----BEGIN CERTIFICATE-----\n\t\t<CA_CERT>\n\t\t-----END CERTIFICATE-----"
    return 1
  fi

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
