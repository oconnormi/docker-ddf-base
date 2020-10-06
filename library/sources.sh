#!/bin/bash

# DDF Catalog sources, passed in the form of 
# <source_type>|<source_name>|<url>|<username>|<password>,<source_type>|...
function sources {
    _number_of_files=0
    IFS=',' read -r -a _source_list <<< "${SOURCES}"
    for index in "${!_source_list[@]}"
    do
        IFS='|' read -r -a _source <<< "${_source_list[$index]}"
        local _source_type=${_source[0]}
        local _source_name=${_source[1]}
        local _url=${_source[2]}

        local _username=${_source[3]}
        local _password=${_source[4]}

        local _source_args="--config-directory ${_app_etc} --template-directory ${_source_template_directory}"

        if [ -n "${_username}" ]; then
            _source_args="${_source_args} --username ${_username}"
        fi
        if [ -n "${_password}" ]; then
            _source_args="${_source_args} --password ${_password}"
        fi
        if [ -n "${_url}" ]; then
            _source_args="${_source_args} --url ${_url}"
        fi

        _source_args="${_source_args} ${_source_type} ${_source_name}"

        echo "Creating DDF Catalog source configuration with arguments: ${_source_args}"
        create-source ${_source_args}
        local status=$?
        if [ $status -ne 0 ]; then
            return $status
        fi
        _number_of_files=$((_number_of_files+1))
    done
    echo "Total number of files created: $_number_of_files"
}

sources
exit $?
