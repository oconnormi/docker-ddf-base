#!/bin/bash


###### Content Directory Monitor Constants #######
_seed_cdm_monitored_path=/seed
_seed_cdm_processing_mechanism=delete
_seed_cdm_max_concurrent_files=1
_seed_cdm_readlock_interval=500
##################################################

function init_seed_cdm {
  create-cdm ${_seed_cdm_monitored_path} \
    --processing-mechanism ${_seed_cdm_processing_mechanism} \
    --threads ${_seed_cdm_max_concurrent_files} \
    --readlock-interval ${_seed_cdm_readlock_interval} \
    --ddf-directory ${APP_HOME}
}

function main {
  init_seed_cdm

  IFS=',' read -r -a _seed_content <<< "${SEED_CONTENT}"
  for index in "${!_seed_content[@]}"
  do
    get_data ${_seed_content[$index]} -o ${_seed_cdm_monitored_path}
  done
}

main
