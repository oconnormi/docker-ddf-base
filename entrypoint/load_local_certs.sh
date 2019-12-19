#!/bin/bash

source ${ENTRYPOINT_HOME}/global_env.sh
source ${ENTRYPOINT_HOME}/certs_env.sh

# imports certificates into trust store
importIntoTrust() {

    _total_certs_imported=0

    if [ -e "${LOCAL_CERTS_DIR}" ]; then
        for file in ${LOCAL_CERTS_DIR}/*.pem; do
            [ -e "$file" ] || continue
            
            filename=${file##*/}  
            filename=${filename%.pem}

            echo "Attempting to import ${filename}"

            keytool -importcert ${_trustStoreOpts} -trustcacerts -alias ${filename} -file ${file} > /dev/null 2>&1
            local _import_success=$?
            
            if [ "${_import_success}" -eq 0 ]; then
                echo "Successfully imported ${filename}"
                _total_certs_imported=$((_total_certs_imported+1))

            else
                echo "Failed to import ${filename}"
                # not sure if the function should exit here. 
                # return 1

            fi
        done

        echo -e "$_total_certs_imported certificate(s) imported\n"
        return 0

    else
        echo "Invalid directory: ${LOCAL_CERTS_DIR}"
        return 1

    fi
}

importIntoTrust
exit $?