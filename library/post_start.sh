#!/bin/bash

echo -n "Waiting for log file: ${APP_LOG} to be created..."
while [ ! -f ${APP_LOG} ]
do
  sleep 1
  echo -n "."
done
echo -e "\nLog file found, continuing..."

waitForReady

if [ -n "$INSTALL_PROFILE" ]; then
  ${_client} profile:install ${INSTALL_PROFILE}
  waitForReady
fi

if [ -n "$INSTALL_FEATURES" ]; then
  IFS=';' read -r -a _install_features <<< "${INSTALL_FEATURES}"
  echo "Preparing to install ${#_install_features[@]} features"
  for index in "${!_install_features[@]}"
  do
    echo "Installing: ${_install_features[$index]}"
    ${_client} "feature:install ${_install_features[$index]}"
  done
fi

if [ -n "$UNINSTALL_FEATURES" ]; then
  IFS=';' read -r -a _uninstall_features <<< "${UNINSTALL_FEATURES}"
  echo "Preparing to uninstall ${#_uninstall_features[@]} features"
  for index in "${!_uninstall_features[@]}"
  do
    echo "Uninstalling: ${_uninstall_features[$index]}"
    ${_client} "feature:uninstall ${_uninstall_features[$index]}"
  done
fi

# TODO: add more fine grained ldap configuration support
if [ -n "$LDAP_HOST" ]; then
  echo "Copying LDAP configs"
  cp $LIBRARY_HOME/config/ldap/*.config ${_app_etc}
fi

if [ -n "$INGEST_DATA" ]; then
  $LIBRARY_HOME/ingest_data.sh
fi

if [ -n "$SEED_CONTENT" ]; then
  $LIBRARY_HOME/seed_content.sh
fi

if [ -n "$CDM" ]; then
  $LIBRARY_HOME/setup_cdm.sh
fi

if [ -n "$REGISTRY" ]; then
    $LIBRARY_HOME/registry.sh
fi

if [ -d "$LIBRARY_HOME/post" ]; then
  for f in "$LIBRARY_HOME/post/*";
    do
      if [ $UID = 0 ]; then
       chmod 755 $f
      else
       sudo chmod 755 $f
      fi
      echo "Running additional post_start configuration: $f"
      $f
    done;
fi

echo "To run additional post_start configurations mount a script to ${LIBRARY_HOME}/post_start_custom.sh"

if [ -e "${LIBRARY_HOME}/post_start_custom.sh" ]; then
  echo "Post-Start Custom Configuration Script found, running now..."
  if [ $UID = 0 ]; then
    chmod 755 ${LIBRARY_HOME}/post_start_custom.sh
  else
    sudo chmod 755 ${LIBRARY_HOME}/post_start_custom.sh
  fi
  sleep 1
  ${LIBRARY_HOME}/post_start_custom.sh
fi

if [ ! "${SSH_ENABLED}" = true ]; then
  echo "SSH_ENABLED not set to true, disabling ssh endpoint"
  sed -i 's/sshPort=8101/#sshPort=8101/' ${_karaf_shell_config_file}
fi
