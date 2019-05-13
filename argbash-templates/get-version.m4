#!/bin/bash

# m4_ignore(
echo "This is just a script template, not the script (yet) - pass it to 'argbash' to fix this." >&2
exit 11  #)Created by argbash-init v2.7.1
# ARG_OPTIONAL_SINGLE([ddf-home], [d], [Path to the ddf home directory. Defaults to '\$APP_HOME'], [$APP_HOME])
# ARG_OPTIONAL_BOOLEAN([platform-version], [p], [Retrieve the platform version], [off])
# ARG_OPTIONAL_BOOLEAN([base-version], [b], [Removes any "-SNAPSHOT" qualifiers from the version string], [off])
# ARG_HELP([<Retrieves version information about a DDF based system. Can get the distribution version and the platform version>])
# ARGBASH_GO

# [ <-- needed because of Argbash

_ddf_system="${_arg_ddf_home}/system"
_ddf_version_file="${_arg_ddf_home}/Version.txt"


function getDistroVersion {
  
  if [ ! -f "${_ddf_version_file}" ]; then
    return 2
  fi
  
  _distro_version=$(cat "${_ddf_version_file}" | awk '{$1=$1};1')
  
  if [ -z "${_distro_version}" ]; then
    return 1
  fi
  
  if [[ "${_distro_version}" =~ (\d+\.)(\d+\.)(\d+).+ ]]; then
    return 4
  fi

  if [ "${_arg_base_version}" = "on" ]; then

    _distro_base_version=${_distro_version%-SNAPSHOT}
    if [[ "${_distro_base_version}" =~ (\d+\.)(\d+\.)(\d+) ]]; then
      return 1
    fi
    echo "${_distro_version%-SNAPSHOT}"

  else
    echo "${_distro_version}"
  fi

  return 0
}

function getPlatformVersion {

  _ddf_platform_version=$(ls "${_ddf_system}/ddf/platform/api/platform-api")

  if [ -z "${_ddf_platform_version}" ]; then
    return 3
  fi

  if [[ "${_ddf_platform_version}" =~ (\d+\.)(\d+\.)(\d+).+ ]]; then
    return 4
  fi

  if [ "${_arg_base_version}" = "on" ]; then
    
    _ddf_platform_base_version="${_ddf_platform_version%-SNAPSHOT}"
    
    if [[ "${_ddf_platform_base_version}" =~ (\d+\.)(\d+\.)(\d+) ]]; then
      return 1
    fi
  
    echo "${_ddf_platform_base_version}"
  else
    echo "${_ddf_platform_version}"
  fi

  return 0
}

function main {

  if [ "${_arg_platform_version}" = "on" ]; then
    getPlatformVersion
  else
    getDistroVersion
  fi
  return $?
}

main
exit $?

# ] <-- needed because of Argbash
