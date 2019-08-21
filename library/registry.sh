#!/bin/bash

# Format for REGISTRY should be REGISTRY=<url>|<name>|<type>|<push>|<pull>|<auto-push>|<username>|<password>,...
function registry {
    IFS=',' read -r -a _registry_list <<< "${REGISTRY}"
    printf "\nPreparing to configure ${#_registry_list[@]} registries\n"
    for index in "${!_registry_list[@]}"
    do
        IFS='|' read -r -a _registry <<< "${_registry_list[$index]}"
        local _registry_url=${_registry[0]}
        local _registry_name=${_registry[1]}
        local _registry_type=${_registry[2]}
        local _registry_push=${_registry[3]}
        local _registry_pull=${_registry[4]}
        local _registry_auto_push=${_registry[5]}
        local _registry_username=${_registry[6]}
        local _registry_password=${_registry[7]}

        local _registry_args=""

        if [ -z "${_registry_url}" ]; then
            return 1
        fi

        if [ -n "${_registry_name}" ]; then
            _registry_args="${_registry_args} --name ${_registry_name}"
        fi

        if [ -n "${_registry_type}" ]; then
            _registry_args="${_registry_args} --type ${_registry_type}"
        fi

        if [ -n "${_registry_push}" ]; then
            _registry_args="${_registry_args} --push"
        fi

        if [ -n "${_registry_pull}" ]; then
            _registry_args="${_registry_args} --pull"
        fi

        if [ -n "${_registry_auto_push}" ]; then
            _registry_args="${_registry_args} --auto-push"
        fi

        if [ -n "${_registry_username}" ]; then
            _registry_args="${_registry_args} --username ${_registry_username}"
        fi

        if [ -n "${_registry_password}" ]; then
            _registry_args="${_registry_args} --password ${_registry_password}"
        fi

        printf "\nConfiguring registry with properties:\n\tURL:\t${_registry_url}\n\tName:\t${_registry_name}\n\tType:\t${_registry_type}\n\tPush:\t${_registry_push}\n\tPull:\t${_registry_pull}\n\tAuto-Push:\t${_registry_auto_push}\n\tUsername:\t${_registry_username}\n\tPassword:\t${_registry_password}\n"

        _registry_args="${_registry_args} ${_registry_url}"
        _registry_config_file=$(add-registry ${_registry_args})
        local status=$?
        if [ $status -ne 0 ]; then
            return $status
        fi
    done
    printf "\nRegistry Configuration Complete\n"
}

registry
exit $?
