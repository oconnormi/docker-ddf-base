package com.github.oconnormi.docker.ddf.entrypoint.config

class Globals {

    public static final SYSTEM_HOSTNAME_PROPERTY = "org.codice.ddf.system.hostname"
    public static final DEFAULT_HOSTNAME = "localhost"
    public static final DEFAULT_SYSTEM_USER = "localhost"
    public static final DEFAULT_KEYSTORE_PASSWORD = "changeit"
    public static final SOLR_HTTP_URL_PROPERTY = "solr.http.url"
    public static final SOLR_CLIENT_PROPERTY = "solr.client"
    public static final SOLR_CLOUD_URL_PROPERTY = "solr.cloud.zookeeper"
    public static final SOLR_HTTP_CLIENT_NAME = "HttpSolrClient"
    public static final SOLR_CLOUD_CLIENT_NAME = "CloudSolrClient"
    public static final CLUSTER_NAME_PROPERTY = "org.codice.ddf.system.cluster.hostname"
    public static final LDAP_HOST_PROPERTY = "org.codice.ddf.ldap.hostname"
    public static final SITE_NAME_PROPERTY = "org.codice.ddf.system.siteName"
}
