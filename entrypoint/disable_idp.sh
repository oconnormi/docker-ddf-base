#!/bin/bash

source ${ENTRYPOINT_HOME}/global_env.sh

_user=admin
_pass=$(grep "${_user} =" ${_users_properties_file} | cut -d '=' -f 2 | cut -d ',' -f 1 | awk '{$1=$1};1')

_auth=$(echo -n "${_user}:${_pass}" | base64)

if [ ! -z "${_pass}" ]; then

  response=$(curl --silent --write-out %{http_code} --output /dev/null -k -X POST \
    "https://${_system_internal_hostname}:${_system_internal_https_port}/admin/jolokia/exec/org.codice.ddf.ui.admin.api.ConfigurationAdmin:service=ui,version=2.3.0/add" \
    -H "Authorization: Basic ${_auth}" \
    -H 'Content-Type: application/json' \
    -H "Origin: ${_system_internal_hostname}:${_system_internal_https_port}" \
    -H "Referer: https://${_system_internal_hostname}:${_system_internal_https_port}" \
    -H 'X-Requested-With: Curl' \
    -H 'cache-control: no-cache' \
    -d @${ENTRYPOINT_HOME}/idp_off.json)
  echo "IdP Disabled Status code: ${repsonse}"
fi
