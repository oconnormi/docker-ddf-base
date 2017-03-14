#!/bin/bash

# Determine app hostname
if [ -n "$APP_HOSTNAME" ]; then
  _app_hostname=$APP_HOSTNAME
else
  _app_hostname=$(hostname -f)
fi

# Prepare Certs
$ENTRYPOINT_HOME/certs.sh

props set org.codice.ddf.system.hostname $_app_hostname $APP_HOME/etc/system.properties
props set org.codice.ddf.system.siteName $_app_hostname $APP_HOME/etc/system.properties
props set $_app_hostname $_app_hostname,group,admin,manager,viewer,system-admin,system-history,systembundles $APP_HOME/etc/users.properties
props del localhost $APP_HOME/etc/users.properties
sed -i "s/localhost/$_app_hostname/" $APP_HOME/etc/users.attributes

if [ -n "$SOLR_ZK_HOSTS" ]; then
  echo "Solr Cloud Support is enabled, zkhosts: $SOLR_ZK_HOSTS"
  props set solr.client CloudSolrClient $APP_HOME/etc/system.properties
  props del solr.http.url $APP_HOME/etc/system.properties
  props set solr.cloud.zookeeper $SOLR_ZK_HOSTS $APP_HOME/etc/system.properties
  props del solr.data.dir $APP_HOME/etc/system.properties
fi

if [ -n "$SOLR_URL" ]; then
  echo "Remote Solr Support is enabled, solr url: $SOLR_URL"
  props set solr.http.url $SOLR_URL $APP_HOME/etc/system.properties
fi

if [ -n "$APP_NODENAME" ]; then
  echo "Cluster support enabled, Node Name: $APP_NODENAME"
  props set org.codice.ddf.system.cluster.hostname $APP_NODENAME $APP_HOME/etc/system.properties
fi

# TODO: add more fine grained ldap configuration support
if [ -n "$LDAP_HOST" ]; then
  echo "Remote LDAP HOST: $LDAP_HOST configured"
  props set org.codice.ddf.ldap.hostname $LDAP_HOST $APP_HOME/etc/system.properties
  if [ -n "$LDAP_PORT" ]; then
    props set org.codice.ddf.ldap.port $LDAP_PORT $APP_HOME/etc/system.properties
  else
    props set org.codice.ddf.ldap.port 1636 $APP_HOME/etc/system.properties
  fi
fi

if [ -d "$ENTRYPOINT_HOME/pre" ]; then
  for f in "$ENTRYPOINT_HOME/pre/*";
    do
      chmod 755 $f
      echo "Running additional pre_start configuration: $f"
      $f
    done;
fi

echo "To run additional pre_start configurations mount a script to ${ENTRYPOINT_HOME}/pre_start_custom.sh"

if [ -e "${ENTRYPOINT_HOME}/pre_start_custom.sh" ]; then
  echo "Pre-Start Custom Configuration Script found, running now..."
  chmod 755 ${ENTRYPOINT_HOME}/pre_start_custom.sh
  sleep 1
  ${ENTRYPOINT_HOME}/pre_start_custom.sh
fi
