#!/bin/bash

# Requests a certificate from a remote CFSSL based CA
source ${ENTRYPOINT_HOME}/certs_env.sh

_tmp_cert_dir=/tmp/ca_remote_request
_tmp_output_dir=${_tmp_cert_dir}/out
mkdir -p ${_tmp_output_dir}

# function join_by { local IFS="$1"; shift; echo "$*"; }
function join_by { local d=$1; shift; echo -n "$1"; shift; printf "%s" "${@/#/$d}"; }

# prepare to sanitize san values for use with cfssl
# cfssl does not require the DNS: and IP: prefixes
_remote_request_key_alg=${CSR_KEY_ALGORITHM:="rsa"}
_remote_request_key_size=${CSR_KEY_SIZE:="2048"}
_remote_request_hosts=${_san}
_remote_request_cn=${_system_external_hostname}
_remote_request_names_country=${CSR_COUNTRY:="US"}
_remote_request_names_locality=${CSR_LOCALITY:="Hursley"}
_remote_request_names_organization=${CSR_ORGANIZATION:="DDF"}
_remote_request_names_organizational_unit=${CSR_ORGANIZATIONAL_UNIT:="Dev"}
_remote_request_names_state=${CSR_STATE:="AZ"}
_remote_request_profile=${CSR_PROFILE:="server"}

IFS=',' read -r -a _remote_request_hosts <<< "${_remote_request_hosts}"
for index in "${!_remote_request_hosts[@]}"
do
  _remote_request_hosts[$index]=${_remote_request_hosts[$index]#DNS:}
  _remote_request_hosts[$index]=${_remote_request_hosts[$index]#IP:}
  _remote_request_hosts[$index]=\"${_remote_request_hosts[$index]}\"
done

_remote_request_hosts=$(join_by ' , ' ${_remote_request_hosts[@]})

cat > ${_tmp_cert_dir}/csr.json << EOF
{
  "request": {
    "CN": "${_remote_request_cn}",
    "hosts": [ ${_remote_request_hosts} ],
    "names": [{
      "C": "${_remote_request_names_country}",
      "L": "${_remote_request_names_locality}",
      "O": "${_remote_request_names_organization}",
      "OU": "${_remote_request_names_organizational_unit}",
      "ST": "${_remote_request_names_state}"
    }],
    "key": {
        "algo": "${_remote_request_key_alg}",
        "size": ${_remote_request_key_size}
    }
  },
  "profile": "${_remote_request_profile}",
  "bundle": true
}
EOF

echo "Generated CSR:"
cat ${_tmp_cert_dir}/csr.json

echo "Submitting CSR to ${_remote_ca}"
curl -k -d @${_tmp_cert_dir}/csr.json \
          ${_remote_ca}/api/v1/cfssl/newcert  \
          | jq . > ${_tmp_cert_dir}/ca-response.json
cat ${_tmp_cert_dir}/ca-response.json | jq .result.certificate --raw-output > ${_tmp_cert_dir}/$_keyAlias.pem
cat ${_tmp_cert_dir}/ca-response.json | jq .result.private_key --raw-output > ${_tmp_cert_dir}/$_keyAlias.key
openssl s_client -connect ${_remote_ca#https://} -showcerts </dev/null 2>/dev/null|openssl x509 -outform PEM > ${_tmp_cert_dir}/ca.pem

cat ${_tmp_cert_dir}/${_keyAlias}.key \
    ${_tmp_cert_dir}/${_keyAlias}.pem \
    ${_tmp_cert_dir}/ca.pem \
    > ${_tmp_output_dir}/${_keyAlias}.pem

openssl pkcs12 \
        -export \
        -out ${_tmp_output_dir}/${_keyAlias}.p12 \
        -in ${_tmp_output_dir}/${_keyAlias}.pem \
        -passin pass:${_storepass} \
        -passout pass:${_storepass} > /dev/null 2>&1

# Import Cert
keytool -importkeystore \
        ${_keytoolOpts} \
        -keypass ${_storepass} \
        -srcstorepass ${_storepass} \
        -srckeystore ${_tmp_output_dir}/${_keyAlias}.p12 > /dev/null 2>&1

keytool -changealias \
        ${_keytoolOpts} \
        -alias 1 \
        -destalias ${_keyAlias} > /dev/null 2>&1

keytool -list -alias "ddf demo root ca" ${_trustStoreOpts} > /dev/null 2>&1
if [ $? -eq 0 ] ; then
  echo "'ddf demo root ca' key found in ${_server_truststore_file}, removing"
  keytool -delete -alias "ddf demo root ca" ${_trustStoreOpts}
fi

keytool -list -alias "ddf demo root ca" ${_keytoolOpts} > /dev/null 2>&1
if [ $? -eq 0 ] ; then
  echo "'ddf demo root ca' key found in ${_server_keystore_file}, removing"
  keytool -delete -alias "ddf demo root ca" ${_keytoolOpts}
fi

keytool -importcert ${_keytoolOpts} -trustcacerts -alias rootCA -file ${_tmp_cert_dir}/ca.pem
keytool -importcert ${_trustStoreOpts} -trustcacerts -alias rootCA -file ${_tmp_cert_dir}/ca.pem
