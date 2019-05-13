#!/bin/bash

_registry_templates_directory=${REGISTRY_TEMPLATE_DIRECTORY:=${ENTRYPOINT_HOME}/templates/registry}
_app_config_directory=${APP_HOME}/etc

# m4_ignore(
echo "This is just a script template, not the script (yet) - pass it to 'argbash' to fix this." >&2
#exit 11  #)Created by argbash-init v2.7.1
# ARG_OPTIONAL_BOOLEAN([pull], [p], [Enable/Disable pulling from the registry])
# ARG_OPTIONAL_BOOLEAN([push], [P], [Enable/Disable pushing to the registry])
# ARG_OPTIONAL_BOOLEAN([auto-push], [a], [Enable publishing of the local identity])
# ARG_OPTIONAL_SINGLE([name], [n], [Full name of registry, Defaults to the registry url when omitted])
# ARG_OPTIONAL_SINGLE([short-name], [s], [Short name of registry. Defaults to the registry url when omitted])
# ARG_OPTIONAL_SINGLE([username], [u], [Username for connecting to the registry])
# ARG_OPTIONAL_SINGLE([password], [w], [Password for connecting to the registry])
# ARG_OPTIONAL_SINGLE([type], [t], [Type of registry to connect to. Requires a matching '.template' file in the registry templates directory], [csw])
# ARG_OPTIONAL_SINGLE([config-directory], [c], [DDF Configuration directory. Defaults to '\$APP_HOME/etc'], [${_app_config_directory}])
# ARG_OPTIONAL_SINGLE([template-directory], [d], [Template directory. Defaults to '\$ENTRYPOINT_HOME/templates/registry', or '\$REGISTRY_TEMPLATES_DIRECTORY' when present], [${_registry_templates_directory}])
# ARG_POSITIONAL_SINGLE([url], [URL for the registry])
# ARG_DEFAULTS_POS
# ARG_HELP([Adds a remote registry configuration for pushing and pulling source configurations], [This utility treats the registry name as the unique identifier for a configuration. If the command is re-run with the same name it will update an existing registry configuration with that name. All registry interaction is turned off unless options are enabled for push, pull, etc. If the 'name' option is not specified it will be set to the value of the url. Templates: All configurations are generated from '.template' files located in the registry templates directory. Template Directory: ${_registry_template_directory}. To set an alternate template directory override the 'REGISTRY_TEMPLATE_DIRECTORY' variable.])
# ARGBASH_GO

# [ <-- needed because of Argbash

declare _type=${_arg_type}.template
declare _template=${_arg_template_directory}/${_type}
declare _service_name
declare _service_pid
declare _config_file

# Retrieves the service name from the template file
function getServiceName {
    local name=$(props get service.factoryPid ${_template})
    if [ $? -ne 0 ] || [ -z ${name} ]; then
        return 2
    fi
    name=${name%\"}
    name=${name#\"}
    echo "${name}"
}

# Gets a pid from an existing configuration
# ARGS: <file>
function getExistingPid {
    local servicePid=$(props get service.pid ${1})
    if [ $? -ne 0 ] || [ -z ${servicePid} ]; then
        return 2
    fi
    servicePid=${servicePid%\"}
    servicePid=${servicePid#\"}
    echo "${servicePid}"
}

# returns an existing config file for a registry with a given name
# returns 1 if no config exists or if more than one exists
function getExistingConfig {
  local results=$(grep -sl "name=\"${_arg_name}\"" ${_arg_config_directory}/${_service_name}-*.config)
  if [ "${#results[@]}" -ne 1 ]; then
    return 1
  fi
  echo "${results}"
}

# Creates a service pid used by the managed service factory
# msf service pid contains a hexadecimal uuid of <8 chars>-<4 chars>-<4 chars>-<4 chars>-<12 chars>
# Service Pid format is <service_name>.<service_uuid>
function generateServicePid() {
  echo "${_service_name}.$(cat /dev/urandom | LC_CTYPE=C tr -dc 'a-f0-9' | fold -w 8 | head -n 1)\
-$(cat /dev/urandom | LC_CTYPE=C tr -dc 'a-f0-9' | fold -w 4 | head -n 1)\
-$(cat /dev/urandom | LC_CTYPE=C tr -dc 'a-f0-9' | fold -w 4 | head -n 1)\
-$(cat /dev/urandom | LC_CTYPE=C tr -dc 'a-f0-9' | fold -w 4 | head -n 1)\
-$(cat /dev/urandom | LC_CTYPE=C tr -dc 'a-f0-9' | fold -w 12 | head -n 1)"
}

# Creates a UUID for use in the config file name
# msf config file needs 32 character uuid in name
function generateConfigUUID() {
  cat /dev/urandom | LC_CTYPE=C tr -dc 'a-f0-9' | fold -w 32 | head -n 1
}

function validateType {
    if [ ! -f "${_arg_template_directory}/${_type}" ]; then
        return 1
    fi
    return 0
}

function validateTemplateDir {
    if [ -z "${_arg_template_directory}" ]; then
        return 1
    fi

    if [ ! -d "${_arg_template_directory}" ]; then
        return 1
    fi
    return 0
}

function validate {
    if ! validateTemplateDir; then
        return 1
    fi

    if ! validateType; then
        return 1
    fi
    return 0
}

function initDefaults {
    if [ -z "${_arg_name}" ]; then
        _arg_name=${_arg_url}
    fi
    if [ -z "${_arg_short_name}" ]; then
        _arg_short_name=${_arg_name}
    fi
}

function initialize {
    if ! validate; then
        return 1
    fi

    initDefaults

    _service_name=$(getServiceName)
    local gotName=$?
    if [ ${gotName} -ne 0 ]; then
        return ${gotName}
    fi

    local existingFile="$(getExistingConfig)"
    if [ ! -z "${existingFile}" ]; then
        _config_file=${existingFile}
        _service_pid=$(getExistingPid ${_config_file})
    else
        _config_file=${_arg_config_directory}/${_service_name}-$(generateConfigUUID).config
        _service_pid=$(generateServicePid)
    fi
    return 0
}

function createConfig {
    export _name=${_arg_name}
    export _short_name=${_arg_short_name}
    export _username=${_arg_username}
    export _password=${_arg_password}
    export _url=${_arg_url}
    export _pid=${_service_pid}

    declare _push="false"
    declare _pull="false"
    declare _auto_push="false"
    if [ "${_arg_push}" = "on" ]; then
        _push="true"
    fi
    if [ "${_arg_pull}" = "on" ]; then
        _pull="true"
    fi
    if [ "${_arg_auto_push}" = "on" ]; then
        _auto_push="true"
    fi

    export _push _pull _auto_push

    envsubst < ${_template} > ${_config_file}
    local _success=$?

    unset _name _short_name _username _password _url _pid _push _pull _auto_push
    return ${_success}
}

function main {
    if ! validate; then
        return 1
    fi
    if ! initialize; then
        return 2
    fi

    if ! createConfig; then
        return 3
    fi

    echo "${_config_file}"
    return 0
}

main
exit $?

# ] <-- needed because of Argbash
