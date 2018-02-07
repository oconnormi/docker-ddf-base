#!/bin/bash

source ${ENTRYPOINT_HOME}/global_env.sh

# Two params
# $1: URL to download
# $2: staging location
function retrieveRemoteData() {
  _url=${1}
  _dest=${2}
  if curl -LsSk -o /dev/null -s -f -r 0-0 "${_url}"; then
    echo -e "Retrieving remote metadata archive.\n\tFrom:\t\t${_url}\n\tStaging:\t${_dest}"
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

  echo -e "Copying local data archive.\n\tFrom:\t${_path}\n\tTo:\t${_dest}"
  mkdir -p $(dirname ${_dest})
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

  if [ -n "${_type}" ]; then
    _type=${_src#*.}
  fi

  echo -e "Extracting archive.\n\tType:\t${_type}\n\tSrc:\t${_src}\n\tDest:\t${_dest}"
  case ${_type} in
    "zip" )
      unzip ${_src} -d ${_dest} && rm -rf ${_src}
      return $?
      ;;
    "tar.gz" )
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

# Two params
# $1: Path to metadata directory
# $2: Transformer
function ingestData() {
  _ingest_directory=${1}
  _xformer=${2}
  if [ -n "${_xformer}" ]; then
    echo -e "Ingesting data:\n\tFrom:\t${_ingest_directory}\n\tType:\t${_xformer}"
    ${_client} "catalog:ingest -t ${_xformer} ${_ingest_directory}"
    return $?
  else
    echo -e "Ingesting data:\n\tFrom:\t${_ingest_directory}"
    ${_client} "catalog:ingest ${_ingest_directory}"
    return $?
  fi
}

function main() {
  _staging_directory="/tmp/ingest"

  IFS=',' read -r -a _ingest_data <<< "${INGEST_DATA}"

  for index in "${!_ingest_data[@]}"
  do
    IFS='|' read -r -a _current_data <<< "${_ingest_data[$index]}"
    _data_location=${_current_data[0]}
    _data_filename=$(basename ${_data_location})
    _data_format=${_data_filename#*.}
    _data_transformer=${_current_data[1]}
    _staging_archive_path="${_staging_directory}/${_data_filename%%.*}/${_data_filename}"
    _staging_path=$(dirname $_staging_archive_path)

    echo -e "Current Data:\n\tLocation:\t${_data_location}\n\tFilename:\t${_data_filename}\n\tFormat: \t${_data_format}\n\tTransformer:\t${_data_transformer}"
    case "${_data_location}" in
      http*://* )
        retrieveRemoteData ${_data_location} ${_staging_archive_path} \
        && unpackData ${_staging_archive_path} ${_staging_path} ${_data_format} \
        && ingestData ${_staging_path} ${_data_transformer}
        return $?
        ;;
      file://* )
        copyLocalData ${_data_location} ${_staging_archive_path} \
        && unpackData ${_staging_archive_path} ${_staging_path} ${_data_format} \
        && ingestData ${_staging_path} ${_data_transformer}
        return $?
        ;;
      * )
        echo -e "Unsupported file location, must be one of\n\thttps://\n\thttp://\n\tfile://"
        return 1
    esac
  done
}

main
exit $?
