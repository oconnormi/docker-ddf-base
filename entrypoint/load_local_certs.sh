#!/bin/bash

source ${ENTRYPOINT_HOME}/global_env.sh
source ${ENTRYPOINT_HOME}/certs_env.sh

_cert_dir=${LOCAL_CERTS_DIR:-"/local_certs"}

importIntoTrust() {
    # imports certificates into trust store

    for file in ${_cert_dir}/*.pem; do
        [ -e "$file" ] || continue
        filename=${file%.pem}
        echo "attempting to import ${filename}"

        keytool -importcert ${_trustStoreOpts} -trustcacerts -alias ${filename} -file ${filename} > /dev/null 2>&1

        local _import_success=$?
        
        if [ "${_import_success}" -eq 0 ]; then
            echo "successfully imported ${file}"
            return 0
        else
            return 1
            echo "Failed to import ${file}"
        fi
    done
    
}

importIntoTrust

exit $?