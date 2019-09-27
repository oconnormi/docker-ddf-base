#!/bin/bash

source ${ENTRYPOINT_HOME}/global_env.sh
source ${ENTRYPOINT_HOME}/certs_env.sh

_tmp_cert_dir=/tmp/remote_certs
mkdir -p ${_tmp_cert_dir}

importTrust() {
    # imports certificates into trust store

    echo "attempting to import $1"

    keytool -importcert ${_keytoolOpts} -trustcacerts -alias ${1} -file ${_tmp_cert_dir}/${1}.pem > /dev/null 2>&1
    local _import_keystore_trust_success=$?

    keytool -importcert ${_trustStoreOpts} -trustcacerts -alias ${1} -file ${_tmp_cert_dir}/${1}.pem > /dev/null 2>&1
    local _import_truststore_trust_success=$?
    
    if [ "${_import_keystore_trust_success}" -eq 0 ] && [ "${_import_truststore_trust_success}" -eq 0 ]; then
        echo "successfully imported $1"
        return 0
    else
        return 1
        echo "import failed $1"
    fi
}

get_certs() {
    # fetch certs from source

    file=${_tmp_cert_dir}/${1}.pem

    if [ -z "$2" ]
    then
        openssl s_client -connect ${1}:443 -showcerts </dev/null 2>/dev/null|openssl x509 -outform PEM > $file
    else
        openssl s_client -connect ${1}:${2} -showcerts </dev/null 2>/dev/null|openssl x509 -outform PEM > $file
    fi
    
    importTrust $1
}

# Remote sources, passed in the form of 
# <url_1>|<url_2>|...
function sources {
    _number_of_sources=0

    IFS='|' read -r -a _remote_sources <<< "${REMOTE_SOURCES}"
    for _url in "${_remote_sources[@]}"
    do
        port="$(echo ${_url} | sed -e 's,^.*:,:,g' -e 's,.*:\([0-9]*\).*,\1,g' -e 's,[^0-9],,g')"

        # extract hostname from url
        hostname=$_url
        hostname=${hostname##*://}
        hostname=${hostname##www.}
        hostname=${hostname%/*}
        hostname=${hostname%%/*}
        hostname=${hostname%%:*}

        get_certs $hostname $port

        local status=$?
        if [ $status -ne 0 ]; then
            return $status
        fi

        _number_of_sources=$((_number_of_sources+1))
    done
    echo "${_number_of_sources} sources processed"
}

sources
exit $?