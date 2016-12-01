#!/bin/bash

if [ -n "$APP_HOSTNAME" ]; then
  _app_hostname=$APP_HOSTNAME
else
  _app_hostname=$(hostname -f)
fi

echo "External Hostname: ${_app_hostname}"
echo "Updating ${APP_NAME} certificates"

echo "APP_HOME: ${APP_HOME}"

chmod 755 $APP_HOME/etc/certs/*.sh

$APP_HOME/etc/certs/CertNew.sh -cn $_app_hostname

sed -i "s/localhost/$_app_hostname/" $APP_HOME/etc/system.properties

sed -i "s/localhost/$_app_hostname/g" $APP_HOME/etc/users.properties

sed -i "s/localhost/$_app_hostname/g" $APP_HOME/etc/users.attributes

sed -i "s/localhost/localhost\ ${_app_hostname}/" /etc/hosts

if [ -n "$SOLR_ZK_HOSTS" ]; then
  echo "Solr Cloud Support is enabled, zkhosts: $SOLR_ZK_HOSTS"
  sed -i 's/solr.client = HttpSolrClient/solr.client = CloudSolrClient/' $APP_HOME/etc/system.properties
  sed -i "/solr.client = CloudSolrClient/a solr.cloud.zookeeper=$SOLR_ZK_HOSTS" $APP_HOME/etc/system.properties
  sed -i 's/solr.http.url/#solr.http.url/g' $APP_HOME/etc/system.properties
  sed -i 's/solr.data.dir/#solr.data.dir/g' $APP_HOME/etc/system.properties
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
