#!/bin/bash

if [ -e "${ENTRYPOINT_HOME}/pre_start.sh" ]; then
  echo "Pre-Start Configuration Script found, running now..."
  chmod 755 ${ENTRYPOINT_HOME}/pre_start.sh && ${ENTRYPOINT_HOME}/pre_start.sh
fi

echo "Starting DDF"

$APP_HOME/bin/start

sleep 2

if [ -e "${ENTRYPOINT_HOME}/post_start.sh" ]; then
  echo "Post-Start Configuration Script found, running now..."
  chmod 755 ${ENTRYPOINT_HOME}/post_start.sh && ${ENTRYPOINT_HOME}/post_start.sh
fi

tail -f $APP_LOG
