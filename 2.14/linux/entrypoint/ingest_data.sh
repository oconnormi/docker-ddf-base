#!/bin/bash

source ${ENTRYPOINT_HOME}/global_env.sh

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
    _data_transformer=${_current_data[1]}
    _staging_path="${_staging_directory}/${_data_filename%%.*}"

    get_data ${_data_location} -o ${_staging_path} \
    && ingestData ${_staging_path} ${_data_transformer}
    return $?
  done
}

main
exit $?
