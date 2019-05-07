#!/bin/bash

source ${ENTRYPOINT_HOME}/global_env.sh

set-guest-attributes -ih ${_system_external_hostname} ${SECURITY_PROFILE}
