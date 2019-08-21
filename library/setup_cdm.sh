#!/bin/bash

# $CDM can contain multiple configs of the form
# <directory>|<processing_mechanism>|<threads>|<readlock>,<directory>|....
function main {
  IFS=',' read -r -a _cdm_configs <<< "${CDM}"
  for index in "${!_cdm_configs[@]}"
  do
    IFS='|' read -r -a _config <<< "${_cdm_configs[$index]}"
    _cdm_directory=${_config[0]}
    _cdm_mechanism=${_config[1]}
    _cdm_threads=${_config[2]}
    _cdm_readlock=${_config[3]}
    _cdm_args="${_cdm_directory}"
    if [ -n "${_cdm_mechanism}" ]; then
      _cdm_args="${_cdm_args} --processing-mechanism ${_cdm_mechanism}"
    fi
    if [ -n "${_cdm_threads}" ]; then
      _cdm_args="${_cdm_args} --threads ${_cdm_threas}"
    fi
    if [ -n "${_cdm_readlock}" ]; then
      _cdm_args="${_cdm_args} --readlock-interval ${_cdm_readlock}"
    fi
    echo "Creating CDM configuration with arguments: ${_cdm_args}"
    create-cdm --ddf-directory ${APP_HOME} ${_cdm_args}
  done
}

main
