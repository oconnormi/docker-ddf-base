#!/bin/bash

source ${ENTRYPOINT_HOME}/global_env.sh

echo -n "Waiting for log file: ${APP_LOG} to be created..."
while [ ! -f ${APP_LOG} ]
do
  sleep 1
  echo -n "."
done
echo -e "\nLog file found, continuing..."

${_client} "while { (bundle:list -t 0 | grep -i \"active.*DDF\s::\sadmin\s::\sUI\" | tac) isEmpty } { echo -n \". \"; sleep 1 }; while {(\"3\" equals ((bundle:list -t 0 | grep -i -v \"active\" | grep -i \"hosts:\" | wc -l | tac) trim) | tac) equals \"false\"} { echo -n \". \"; sleep 1 }; echo \"\"; echo \"System Ready\""

if [ -n "$INSTALL_PROFILE" ]; then
  ${_client} profile:install ${INSTALL_PROFILE}
fi

if [ -n "$INSTALL_FEATURES" ]; then
  IFS=';' read -r -a INSTALL_FEATURES <<< "${INSTALL_FEATURES}"
  echo "Preparing to install ${#INSTALL_FEATURES[@]} features"
  for index in "${!INSTALL_FEATURES[@]}"
  do
    echo "Installing: ${INSTALL_FEATURES[$index]}"
    ${_client} "feature:install ${INSTALL_FEATURES[$index]}"
  done
fi

if [ -n "$UNINSTALL_FEATURES" ]; then
  IFS=';' read -r -a UNINSTALL_FEATURES <<< "${UNINSTALL_FEATURES}"
  echo "Preparing to uninstall ${#UNINSTALL_FEATURES[@]} features"
  for index in "${!UNINSTALL_FEATURES[@]}"
  do
    echo "Uninstalling: ${UNINSTALL_FEATURES[$index]}"
    ${_client} "feature:uninstall ${UNINSTALL_FEATURES[$index]}"
  done
fi

# TODO: add more fine grained ldap configuration support
if [ -n "$LDAP_HOST" ]; then
  echo "Copying LDAP configs"
  cp $ENTRYPOINT_HOME/config/ldap/*.config ${_app_etc}
fi

if [ -n "$INGEST_DATA" ]; then
  $ENTRYPOINT_HOME/ingest_data.sh
fi

if [ -d "$ENTRYPOINT_HOME/post" ]; then
  for f in "$ENTRYPOINT_HOME/post/*";
    do
      chmod 755 $f
      echo "Running additional post_start configuration: $f"
      $f
    done;
fi

echo "To run additional post_start configurations mount a script to ${ENTRYPOINT_HOME}/post_start_custom.sh"

if [ -e "${ENTRYPOINT_HOME}/post_start_custom.sh" ]; then
  echo "Post-Start Custom Configuration Script found, running now..."
  chmod 755 ${ENTRYPOINT_HOME}/post_start_custom.sh
  sleep 1
  ${ENTRYPOINT_HOME}/post_start_custom.sh
fi

if [ ! "${SSH_ENABLED}" = true ]; then
  echo "SSH_ENABLED not set to true, disabling ssh endpoint"
  sed -i 's/sshPort=8101/#sshPort=8101/' ${_karaf_shell_config_file}
fi
