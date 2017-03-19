package com.github.oconnormi.docker.ddf.entrypoint.config

import java.nio.file.Path
import java.nio.file.Paths

class EntrypointConfig {
    private AppMetadata appMetadata
    private String hostname
    private String solrMode
    private String solrUrl
    private String siteName
    private String clusterName
    private String ldapHost
    private Path installConfigPath

    /**
     * Entrypoint Configuration for DDF Based Systems
     * @param appMetadata - Container metadata related to installed ddf instance
     * @param options - options for ddf setup
     */
    EntrypointConfig(AppMetadata appMetadata, options) {
        this.appMetadata = appMetadata

        this.hostname = InetAddress.getLocalHost().canonicalHostName
        this.solrMode = options.'solr-mode'
        this.solrUrl = options.s
        this.siteName = options.sitename
        this.clusterName = options.c
        this.ldapHost = options.l
        this.installConfigPath = Paths.get(options.i)
    }

    AppMetadata getAppMetadata() {
        return appMetadata
    }

    void setAppMetadata(AppMetadata appMetadata) {
        this.appMetadata = appMetadata
    }

    String getHostname() {
        return hostname
    }

    void setHostname(String hostname) {
        this.hostname = hostname
    }

    String getSolrMode() {
        return solrMode
    }

    void setSolrMode(String solrMode) {
        this.solrMode = solrMode
    }

    String getSolrUrl() {
        return solrUrl
    }

    void setSolrUrl(String solrUrl) {
        this.solrUrl = solrUrl
    }

    String getSiteName() {
        return siteName
    }

    void setSiteName(String siteName) {
        this.siteName = siteName
    }

    String getClusterName() {
        return clusterName
    }

    void setClusterName(String clusterName) {
        this.clusterName = clusterName
    }

    String getLdapHost() {
        return ldapHost
    }

    void setLdapHost(String ldapHost) {
        this.ldapHost = ldapHost
    }

    Path getInstallConfigPath() {
        return installConfigPath
    }

    void setInstallConfigPath(String installConfigPath) {
        this.installConfigPath = Paths.get(installConfigPath)
    }
}
