#!/bin/bash

source ${ENTRYPOINT_HOME}/global_env.sh

curl -k -X POST \
  "https://${_system_internal_hostname}:${_system_internal_https_port}/admin/jolokia/exec/org.codice.ddf.ui.admin.api.ConfigurationAdmin:service=ui,version=2.3.0/add" \
  -H 'Authorization: Basic YWRtaW46YWRtaW4=' \
  -H 'Content-Type: application/json' \
  -H "Origin: ${_system_internal_hostname}:${_system_internal_https_port}" \
  -H "Referer: https://${_system_internal_hostname}:${_system_internal_https_port}" \
  -H 'X-Requested-With: Curl' \
  -H 'cache-control: no-cache' \
  -d @${ENTRYPOINT_HOME}/idp_off.json
