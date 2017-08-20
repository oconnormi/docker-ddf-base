#!/bin/bash

# Skip seeding the config volume if skip options detected
if [ -z "$SKIP_CONFIG_SEEDING" ] || [ -z "$SKIP_ALL_SEEDING" ]; then
  echo "Seeding ${APP_HOME}/etc to ${APP_CONFIG} volume"
  rsync --ignore-existing --remove-source-files -raz ${APP_HOME}/etc/ ${APP_CONFIG}
fi

# Skip seeding the data volume if skip options detected
if [ -z "$SKIP_DATA_SEEDING" ] || [ -z "$SKIP_ALL_SEEDING" ]; then
  echo "Seeding ${APP_HOME}/data to ${APP_DATA} volume"
  rsync --ignore-existing --remove-source-files  -raz ${APP_HOME}/data/ ${APP_DATA}
fi

if [ -z "$SKIP_DEPLOY_SEEDING" ] || [ -z "$SKIP_ALL_SEEDING" ]; then
  echo "Seeding ${APP_HOME}/deploy to $APP_DEPLOY volume"
  rsync -raz ${APP_HOME}/deploy/ ${APP_DEPLOY}
fi
