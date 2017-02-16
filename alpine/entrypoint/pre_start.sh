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
  cp $ENTRYPOINT_HOME/config/ldap/*.config $APP_HOME/etc/
  props set org.codice.ddf.ldap.hostname $LDAP_HOST $APP_HOME/etc/system.properties
fi

if [ -n "$STARTUP_APPS" ]; then
  echo "Configuring startup apps"
  if [[ $STARTUP_APPS == *";"* ]]; then
  _appCount=$[$(echo $STARTUP_APPS | grep -o ";" | wc -l) + 1]
  else
    _appCount=1
  fi

  echo "Adding $_appCount startup apps"

  for (( i=1; i<=$_appCount; i++ ))
  do
    _currentApp=$(echo $STARTUP_APPS | cut -d ";" -f $i)
    echo "Adding: $_currentApp"
    props set $_currentApp '' $APP_HOME/etc/org.codice.ddf.admin.applicationlist.properties
  done
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
  chmod 755 ${ENTRYPOINT_HOME}/pre_start_custom.sh && ${ENTRYPOINT_HOME}/pre_start_custom.sh
fi
