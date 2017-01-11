#!/bin/bash

if [ -n "$APP_HOSTNAME" ]; then
  _app_hostname=$APP_HOSTNAME
else
  _app_hostname=$(hostname -f)
fi

echo "External Hostname: ${_app_hostname}"
echo "Updating ${APP_NAME} certificates"

chmod 755 $APP_HOME/etc/certs/*.sh

$APP_HOME/etc/certs/CertNew.sh -cn $_app_hostname >> /dev/null

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

if [ -n "$NODE_NAME" ]; then
  echo "Cluster support enabled, Node Name: $NODE_NAME"
  props set org.codice.ddf.system.nodename $NODE_NAME $APP_HOME/etc/system.properties
  props set org.codice.ddf.system.x509crl etc/certs/demoCA/crl/crl.pem $APP_HOME/etc/system.properties

  props set org.apache.ws.security.crypto.merlin.keystore.alias '${org.codice.ddf.system.nodename}' $APP_HOME/etc/ws-security/issuer/signature.properties
  props set org.apache.ws.security.crypto.merlin.x509crl.file '${org.codice.ddf.system.x509crl}' $APP_HOME/etc/ws-security/issuer/signature.properties
  props set org.apache.ws.security.crypto.merlin.keystore.alias '${org.codice.ddf.system.nodename}' $APP_HOME/etc/ws-security/issuer/encryption.properties
  props set org.apache.ws.security.crypto.merlin.x509crl.file '${org.codice.ddf.system.x509crl}' $APP_HOME/etc/ws-security/issuer/encryption.properties

  props set org.apache.ws.security.crypto.merlin.keystore.alias '${org.codice.ddf.system.nodename}' $APP_HOME/etc/ws-security/server/signature.properties
  props set org.apache.ws.security.crypto.merlin.x509crl.file '${org.codice.ddf.system.x509crl}' $APP_HOME/etc/ws-security/server/signature.properties
  props set org.apache.ws.security.crypto.merlin.keystore.alias '${org.codice.ddf.system.nodename}' $APP_HOME/etc/ws-security/server/encryption.properties
  props set org.apache.ws.security.crypto.merlin.x509crl.file '${org.codice.ddf.system.x509crl}' $APP_HOME/etc/ws-security/server/encryption.properties
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
