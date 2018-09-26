#!/bin/bash

# m4_ignore(
echo "This is just a script template, not the script (yet) - pass it to 'argbash' to fix this." >&2
exit 11  #)Created by argbash-init v2.6.1
# ARG_OPTIONAL_SINGLE([output], [o], [Specify the output location], [/tmp])
# ARG_POSITIONAL_SINGLE([data_source], [Specify the location of the source data. Supported protocols are http(s):// and file://])
# ARG_DEFAULTS_POS
# ARG_HELP([Retrieves archived data from a local or remote source and unpacks it])
# ARGBASH_GO

# [ <-- needed because of Argbash 

_archive_staging_path=/tmp/get_data/archives

# Two params
# $1: URL to download
# $2: staging location
function retrieveRemoteData() {
  _url=${1}
  _dest=${2}
  echo -e "Retrieving remote metadata archive.\n\tFrom:\t\t${_url}\n\tStaging:\t${_dest}"
  if curl -LsSk -o /dev/null -s -f -r 0-0 "${_url}"; then
    mkdir -p $(dirname ${_dest})
    curl -LsSk ${_url} -o ${_dest}
    return 0
  else
    echo "Unable to retrieve from: ${_url}"
    return 1
  fi
}

# Two params
# $1: Path to copy from
# $2: Path to copy to
function copyLocalData() {
  _path=${1#*//}
  _dest=${2}
  if [ ! -f ${_path} ]; then
    echo "Local data archive: ${_path} does not exist!"
    return 1
  fi

  mkdir -p $(dirname ${_dest})
  echo -e "Copying local data archive.\n\tFrom:\t${_path}\n\tTo:\t${_dest}"
  cp ${_path} ${_dest}
  if [ ! -f ${_dest} ]; then
    echo "Unable to stage archive to destination: ${_dest}"
    return 1
  fi
}

# Three params
# $1: src path for archive
# $2: dest path for extraction
# $2: archive type
function unpackData() {
  _src=${1}
  _dest=${2}
  _type=${3}

  mkdir -p ${_dest}

  if [ -n "${_type}" ]; then
    _type=${_src#*.}
  fi

  echo -e "Extracting archive.\n\tType:\t${_type}\n\tSrc:\t${_src}\n\tDest:\t${_dest}"
  case ${_type} in
    "zip" )
      unzip -q ${_src} -d ${_dest} && rm -rf ${_src}
      return $?
      ;;
    "tar.gz" | "tgz" )
      tar xzf ${_src} -C ${_dest} && rm -rf ${_src}
      return $?
      ;;
    "tar" )
      tar xf ${_src} -C ${_dest} && rm -rf ${_src}
      return $?
      ;;
    * )
      echo "Unsupported archive type"
      return 1
  esac
}

function main {

  mkdir -p ${_archive_staging_path}

  _data_filename=$(basename ${_arg_data_source})
  _data_format=${_data_filename#*.}
  _tmp_path="${_archive_staging_path}/${_data_filename}"
  _staging_archive_path="${_arg_output}/${_data_filename%%.*}/${_data_filename}"

  case "${_arg_data_source}" in
    http*://* )
      retrieveRemoteData ${_arg_data_source} ${_tmp_path} \
      && unpackData ${_tmp_path} ${_arg_output} ${_data_format} \
      return $?
      ;;
    file://* )
      copyLocalData ${_arg_data_source} ${_tmp_path} \
      && unpackData ${_tmp_path} ${_arg_output} ${_data_format} \
      return $?
      ;;
    * )
      echo -e "Unsupported file location, must be one of\n\thttps://\n\thttp://\n\tfile://"
      return 1
  esac

}

main
exit $?

# ] <-- needed because of Argbash
