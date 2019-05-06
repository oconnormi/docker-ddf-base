#!/bin/bash
source ${ENTRYPOINT_HOME}/global_env.sh

props set fanoutEnabled true ${_app_etc}/ddf.catalog.CatalogFrameworkImpl.config
