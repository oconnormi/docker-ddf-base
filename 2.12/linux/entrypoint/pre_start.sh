#!/bin/bash

source ${ENTRYPOINT_HOME}/global_env.sh

# Prepare Certs
${ENTRYPOINT_HOME}/certs.sh

props set ${_system_hostname_key} ${_app_hostname} ${_system_properties_file}
props set ${_system_sitename_key} ${_app_hostname} ${_system_properties_file}
props del localhost ${_users_properties_file}
props set ${_app_hostname} ${_system_user_privileges} ${_users_properties_file}
sed -i "s/localhost/$_app_hostname/" ${_users_attributes_file}

if [ -n "$SOLR_ZK_HOSTS" ]; then
  echo "Solr Cloud Support is enabled, zkhosts: $SOLR_ZK_HOSTS"
  props set ${_solr_client_key} CloudSolrClient ${_system_properties_file}
  props del ${_solr_http_url_key} ${_system_properties_file}
  props set ${_solr_cloud_url_key} $SOLR_ZK_HOSTS ${_system_properties_file}
  props del ${_solr_data_key} ${_system_properties_file}
fi

if [ -n "$SOLR_URL" ]; then
  echo "Remote Solr Support is enabled, solr url: $SOLR_URL"
  props set ${_solr_http_url_key} ${SOLR_URL} ${_system_properties_file}
fi

# TODO: add more fine grained ldap configuration support
if [ -n "$LDAP_HOST" ]; then
  echo "Remote LDAP HOST: ${LDAP_HOST} configured"
  props set ${_ldap_hostname_key} ${LDAP_HOST} ${_system_properties_file}
  props set ${_ldap_port_key} ${_ldap_port} ${_system_properties_file}
fi

if [ -n "$HTTPS_PORT" ]; then
   props set ${_system_https_port_key} ${HTTPS_PORT} ${_system_properties_file}
fi

if [ -n "$JAVA_MAX_MEM" ]; then
   sed -i "s/Xmx.* /Xmx${JAVA_MAX_MEM}g /g" ${_setenv_file}
fi

# Copy any existing configuration files before starting the container
if [ -d "$ENTRYPOINT_HOME/pre_config" ]; then
  echo "Copying configuration files from ${ENTRYPOINT_HOME}/pre_config to ${APP_HOME}"
  cp -r ${ENTRYPOINT_HOME}/pre_config/* ${APP_HOME}
fi

if [ -d "$ENTRYPOINT_HOME/pre" ]; then
  for f in "$ENTRYPOINT_HOME/pre/*";
    do
      chmod 755 $f
      echo "Running additional pre_start configuration: $f"
      $f
    done;
fi

# Enable SSH endpoint
sed -i 's/#sshPort=8101/sshPort=8101/' ${_karaf_shell_config_file}

echo "To run additional pre_start configurations mount a script to ${ENTRYPOINT_HOME}/pre_start_custom.sh"

if [ -e "${ENTRYPOINT_HOME}/pre_start_custom.sh" ]; then
  echo "Pre-Start Custom Configuration Script found, running now..."
  chmod 755 ${ENTRYPOINT_HOME}/pre_start_custom.sh
  sleep 1
  ${ENTRYPOINT_HOME}/pre_start_custom.sh
fi
