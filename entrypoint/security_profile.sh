#!/bin/bash

source ${ENTRYPOINT_HOME}/global_env.sh

printf "Security Profile is set to ${SECURITY_PROFILE}/n"

set-guest-attributes -iH ${_system_internal_hostname} ${SECURITY_PROFILE}
