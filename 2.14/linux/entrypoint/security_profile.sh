#!/bin/bash

source ${ENTRYPOINT_HOME}/global_env.sh

set-guest-attributes -h ${_system_external_hostname} -ip ${SECURITY_PROFILE}
