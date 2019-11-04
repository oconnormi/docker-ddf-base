#!/bin/bash

source ${ENTRYPOINT_HOME}/global_env.sh

_user=$(grep ${_users_properties_file} admin= | cut -d '=' -f 1)
_pass=$(grep ${_users_properties_file} admin= | cut -d '=' -f 2 | cut -d ',' -f 1 | )

_auth=$(echo "${_user}:${_pass}" | base64)

if [ ! -z "${_pass}" ]; then

  curl --head --silent --output /dev/null -k -X POST \
    "https://${_system_internal_hostname}:${_system_internal_https_port}/admin/jolokia/exec/org.codice.ddf.ui.admin.api.ConfigurationAdmin:service=ui,version=2.3.0/add" \
    -H "Authorization: Basic ${_auth}" \
    -H 'Content-Type: application/json' \
    -H "Origin: ${_system_internal_hostname}:${_system_internal_https_port}" \
    -H "Referer: https://${_system_internal_hostname}:${_system_internal_https_port}" \
    -H 'X-Requested-With: Curl' \
    -H 'cache-control: no-cache' \
    -d @${ENTRYPOINT_HOME}/idp_off.json
fi
