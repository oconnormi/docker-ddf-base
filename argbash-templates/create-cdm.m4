#!/bin/bash

# m4_ignore(
echo "This is just a script template, not the script (yet) - pass it to 'argbash' to fix this." >&2
exit 11  #)Created by argbash-init v2.6.1
# ARG_OPTIONAL_SINGLE([processing-mechanism], [p], [behavior when files are processed. Choices are in_place, move, and delete], [in_place])
# ARG_OPTIONAL_SINGLE([threads], [t], [specify the number of threads to use for processing files], [1])
# ARG_OPTIONAL_SINGLE([ddf-directory], [d], [Directory where ddf instance is located], [$(pwd)])
# ARG_OPTIONAL_SINGLE([readlock-interval], [r], [specify the amount of time to wait before acquiring a file lock], [500])
# ARG_OPTIONAL_REPEATED([attribute-override], [o], [Specify attribute overrides of the form 'key=value' (Not yet supported!)])
# ARG_POSITIONAL_SINGLE([directory], [Specify the path to the directory to be monitored])
# ARG_DEFAULTS_POS
# ARG_HELP([Create a ContentDirectoryMonitor for a specified directory. Nothing will be done if configuration already exists])
# ARGBASH_GO

# [ <-- needed because of Argbash 

_ddf_etc=${KARAF_ETC:="${_arg_ddf_directory}/etc"}
_ddf_security=${_arg_ddf_directory}/security

###### Content Directory Monitor Constants #######
# Basic CDM properties
_cdm_pid=org.codice.ddf.catalog.content.monitor.ContentDirectoryMonitor
_cdm_config_extension=config
##################################################

####### URL Resource Reader Constants #######
# Basic URL Resource Reader properties
_url_resource_reader_pid=ddf.catalog.resource.impl.URLResourceReader
_url_resource_reader_config_extension=config
##################################################

# Checks if a CDM configuration exists for a given path
function cdmConfigExists {
  shopt -s extglob
  local result=$(find ${_ddf_etc} -type f -name "${_cdm_pid}*" -exec grep -H "${_arg_directory}" {} \; | wc -l)
  result=${result##*( )}
  result=${result%%*( )}
  shopt -u extglob
  echo "${result}"
}

# Creates a cdm service pid used by the managed service factory
# msf service pid contains a hexadecimal uuid of <8 chars>-<4 chars>-<4 chars>-<4 chars>-<12 chars>
# Service Pid format is <cdm_pid>.<service_uuid>
function generateServicePid() {
  echo "${_cdm_pid}.$(cat /dev/urandom | LC_CTYPE=C tr -dc 'a-f0-9' | fold -w 8 | head -n 1)\
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

# Generates CDM security policy for the directory being monitored
function genCdmSecPolicy() {
  local header="CDM Permissions for ${_arg_directory}"
  if ! grep -q "${header}" ${_ddf_security}/configurations.policy; then
    sed -i.bak "/Add required CDM permissions here/a\\
\\
\\    // ${header}:\\
\\    permission java.io.FilePermission \"${_arg_directory}\", \"read\";\\
\\    permission java.io.FilePermission \"${_arg_directory}\${\/}-\", \"read, write\";
" ${_ddf_security}/configurations.policy
  fi
}

# Generates URL Resource Reader security policy for the directory being monitored
function genUrlSecPolicy() {
  local header="URL Resource Reader Permissions for ${_arg_directory}"
  if ! grep -q "${header}" ${_ddf_security}/configurations.policy; then
    sed -i.bak "/Add required URL Resource Reader permissions here/a\\
\\
\\    // ${header}:\\
\\    permission java.io.FilePermission \"${_arg_directory}\", \"read\";\\
\\    permission java.io.FilePermission \"${_arg_directory}\${\/}-\", \"read\";
" ${_ddf_security}/configurations.policy
  fi
}

# Creates URL Resource Reader config
function createUrlConfig() {
  local _url_resource_reader_config_path=${_ddf_etc}/${_url_resource_reader_pid}.${_url_resource_reader_config_extension}
  if [ ! -f ${_url_resource_reader_config_path} ]; then
    cat > ${_url_resource_reader_config_path} << EOF
followRedirects=B"false"
rootResourceDirectories=[ \\
  "data/products", \\
  ]
service.pid="${_url_resource_reader_pid}"
EOF
  fi
  if ! grep -q "${_arg_directory}" ${_url_resource_reader_config_path}; then
    sed -i.bak "/data\/products/a\\
\\  \"${_arg_directory}\", \\\
\\
" ${_url_resource_reader_config_path}
  fi
}

# Create a configuration for with the provided cdm options
function createCdmConfig() {
  local _cdm_config_path=${_ddf_etc}/${_cdm_pid}-$(generateConfigUUID).${_cdm_config_extension}
  local _cdm_service_pid=$(generateServicePid)
  cat > ${_cdm_config_path} << EOF
monitoredDirectoryPath="${_arg_directory}"
processingMechanism="${_arg_processing_mechanism}"
numThreads=I"${_arg_threads}"
readLockIntervalMilliseconds=I"${_arg_readlock_interval}"
service.factoryPid="${_cdm_pid}"
service.pid="${_cdm_service_pid}"
EOF
}

# returns 0 when successful, 1 if config already exists
function main {
  exists=$(cdmConfigExists)
  if [ "${exists}" -ne 0 ]; then
    echo "CDM already exists for directory ${_arg_directory}, skipping"
    return 1
  else
    echo "Creating CDM permissions and configuration for ${_arg_directory}"
    if genCdmSecPolicy && createCdmConfig; then 
      echo "Done"
      if [ "${_arg_processing_mechanism}" == "in_place" ]; then
        echo "Creating URL Resource Reader permissions and configuration for ${_arg_directory}"
        genUrlSecPolicy && createUrlConfig && echo "Done" && return 0
      fi
      return 0
    fi
  fi
}

main

# ] <-- needed because of Argbash
