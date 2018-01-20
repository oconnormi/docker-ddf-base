#!/bin/bash

source $ENTRYPOINT_HOME/certs_env.sh

_subject="/C=US/ST=AZ/L=Hursley/O=DDF/OU=Dev/CN=$_app_hostname"
_serial=$(cat /dev/urandom | tr -dc '0-9' | fold -w 16 | head -n 1)

echo "External Hostname: ${_app_hostname}"
echo "Alternative Names: $_san"
echo "Updating ${APP_NAME} certificates"

# Generate random serial
echo $_serial > $APP_HOME/etc/certs/demoCA/serial

# Generate key
openssl genrsa \
  -out $APP_HOME/etc/certs/demoCA/private/$_keyAlias.key \
  4096 > /dev/null 2>&1

# Generate CSR
export _san
openssl req \
  -new \
  -sha256 \
  -subj $_subject \
  -key $APP_HOME/etc/certs/demoCA/private/$_keyAlias.key \
  -out $APP_HOME/etc/certs/demoCA/$_keyAlias.csr \
  -config $ENTRYPOINT_HOME/ca/openssl-demo.cnf > /dev/null 2>&1

echo "unique_subject = no" > $APP_HOME/etc/certs/demoCA/index.txt.attr
# Sign request using DDF Demo CA

openssl ca \
        -batch \
        -config $ENTRYPOINT_HOME/ca/openssl-demo.cnf \
        -passin pass:secret \
        -in $APP_HOME/etc/certs/demoCA/$_keyAlias.csr \
        -out $APP_HOME/etc/certs/demoCA/newcerts/$_keyAlias.cer > /dev/null 2>&1

cat $APP_HOME/etc/certs/demoCA/cacert.pem \
    $APP_HOME/etc/certs/demoCA/newcerts/$_keyAlias.cer \
    $APP_HOME/etc/certs/demoCA/private/$_keyAlias.key \
    > $APP_HOME/etc/certs/demoCA/private/$_keyAlias.pem

openssl pkcs12 \
        -export \
        -out $APP_HOME/etc/certs/demoCA/private/$_keyAlias.p12 \
        -in $APP_HOME/etc/certs/demoCA/private/$_keyAlias.pem \
        -passin pass:$_storepass \
        -passout pass:$_storepass > /dev/null 2>&1

# Import Cert
keytool -importkeystore \
        $_keytoolOpts \
        -keypass $_storepass \
        -srcstorepass $_storepass \
        -srckeystore $APP_HOME/etc/certs/demoCA/private/$_keyAlias.p12 > /dev/null 2>&1

keytool -changealias \
        $_keytoolOpts \
        -alias 1 \
        -destalias $_keyAlias > /dev/null 2>&1
