#!/bin/bash

if [ -e "${ENTRYPOINT_HOME}/pre_start.sh" ]; then
  echo "Pre-Start Configuration Script found, running now..."
  chmod 755 ${ENTRYPOINT_HOME}/pre_start.sh
  sleep 1
  ${ENTRYPOINT_HOME}/pre_start.sh
fi

echo "Starting ${APP_NAME}"

if [ -n "$HTTPS_PORT" ] && [ "$HTTPS_PORT" -lt "1024" ] && [ $EUID -ne 0 ]; then
  sudo -E $APP_HOME/bin/start
else
  $APP_HOME/bin/start
fi

sleep 2

if [ -e "${ENTRYPOINT_HOME}/post_start.sh" ]; then
  echo "Post-Start Configuration Script found, running now..."
  chmod 755 ${ENTRYPOINT_HOME}/post_start.sh
  sleep 1
  ${ENTRYPOINT_HOME}/post_start.sh
fi

tail -f $APP_LOG
