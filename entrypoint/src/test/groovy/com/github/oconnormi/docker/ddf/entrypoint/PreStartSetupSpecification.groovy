package com.github.oconnormi.docker.ddf.entrypoint

import com.github.oconnormi.docker.ddf.entrypoint.config.AppMetadata
import com.github.oconnormi.docker.ddf.entrypoint.config.EntrypointConfig
import groovy.json.JsonSlurper
import org.codehaus.groovy.util.StringUtil
import org.junit.Ignore
import org.junit.Rule
import org.junit.rules.TemporaryFolder
import spock.lang.Specification

import java.nio.file.Files
import java.nio.file.Path
import java.nio.file.Paths
import java.security.KeyStore
import java.security.cert.Certificate
import java.security.cert.X509Certificate

class PreStartSetupSpecification extends Specification {

    private static final SYSTEM_HOSTNAME_PROPERTY = "org.codice.ddf.system.hostname"
    private static final DEFAULT_HOSTNAME = "localhost"
    private static final DEFAULT_SYSTEM_USER = "localhost"
    private static final DEFAULT_KEYSTORE_PASSWORD = "changeit"
    private static final SOLR_HTTP_URL_PROPERTY = "solr.http.url"
    private static final SOLR_CLIENT_PROPERTY = "solr.client"
    private static final SOLR_CLOUD_URL_PROPERTY = "solr.cloud.zookeeper"
    private static final SOLR_HTTP_CLIENT_NAME = "HttpSolrClient"
    private static final SOLR_CLOUD_CLIENT_NAME = "CloudSolrClient"
    private static final CLUSTER_NAME_PROPERTY = "org.codice.ddf.system.cluster.hostname"
    private static final LDAP_HOST_PROPERTY = "org.codice.ddf.ldap.hostname"

    @Rule TemporaryFolder tmp
    PreStartSetup preStartSetup = new PreStartSetup()
    Path systemHome
    Path systemLog
    String systemName = "test-system"
    Path systemProps
    Path systemUserProps
    Path systemUserAttr
    AppMetadata testMinimalAppMetadata
    EntrypointConfig minimalConfig
    String testHostname = "foo.local"
    Path keyStorePath

    def setup() {
        systemHome = tmp.newFolder("test").toPath()
        createSystemFolder(systemHome)

        testMinimalAppMetadata = new AppMetadata(systemName, systemHome, systemLog)
        minimalConfig = Stub()

        minimalConfig.getAppMetadata() >> testMinimalAppMetadata
        minimalConfig.getHostname() >> testHostname
    }

    def "it should update system properties with the current hostname"() {
        setup:
            Properties testProperties
        when:
            preStartSetup.run(minimalConfig)
            testProperties = loadPropFile(systemProps)
        then:
            assert testProperties.get(SYSTEM_HOSTNAME_PROPERTY) == minimalConfig.hostname
    }

    def "it should remove the default system user"() {
        setup:
            Properties testProperties
        when:
            preStartSetup.run(minimalConfig)
            testProperties = loadPropFile(systemUserProps)
        then:
            assert testProperties.get(DEFAULT_SYSTEM_USER) == null
    }

    def "it should update the system user to match the current hostname"() {
        setup:
            String expectedPassPerm = "${testHostname},group,admin,manager,viewer,system-admin,system-history,systembundles"
            Properties testProperties
        when:
            preStartSetup.run(minimalConfig)
            testProperties = loadPropFile(systemUserProps)
        then:
            assert testProperties.get(testHostname) == expectedPassPerm
    }

    def "it should remove the default system user from the user attributes file"() {
        setup:
            def userAttrs
        when:
            preStartSetup.run(minimalConfig)
            userAttrs = new JsonSlurper().parse(systemUserAttr.toFile())
        then:
            assert userAttrs."${DEFAULT_SYSTEM_USER}" == null
    }

    def "it should add a new system user matching the hostname to the user attributes file"() {
        setup:
            def userAttrs
        when:
            preStartSetup.run(minimalConfig)
            userAttrs = new JsonSlurper().parse(systemUserAttr.toFile())
        then:
            assert userAttrs."${testHostname}" != null
    }

    def "it should remove the default certificates from the server keystore"() {
        setup:
            def keystore
        when:
            preStartSetup.run(minimalConfig)
            keystore = loadKeystore(keyStorePath)
        then:
            assert !keystore.containsAlias(DEFAULT_HOSTNAME)
    }

    def "it should add a new certificate matching the current hostname"() {
        setup:
            def keystore
        when:
            preStartSetup.run(minimalConfig)
            keystore = loadKeystore(keyStorePath)
        then:
            assert keystore.containsAlias(testHostname)
    }

    def "it should set the remote solr url when when solr mode is set to default"() {
        setup:
            String solrUrl = "https://bar.local:8993/solr"
            minimalConfig.solrUrl >> solrUrl
            Properties testProperties
        when:
            preStartSetup.run(minimalConfig)
            testProperties = loadPropFile(systemProps)
        then:
            assert testProperties.get(SOLR_CLIENT_PROPERTY) == SOLR_HTTP_CLIENT_NAME
            assert testProperties.get(SOLR_HTTP_URL_PROPERTY) == solrUrl
    }

    def "it should set the remote solr url when the solr mode is set to http"() {
        setup:
            String solrUrl = "https://bar.local:8993/solr"
            minimalConfig.solrMode >> "http"
            minimalConfig.solrUrl >> solrUrl
            Properties testProperties
        when:
            preStartSetup.run(minimalConfig)
            testProperties = loadPropFile(systemProps)
        then:
            assert testProperties.get(SOLR_CLIENT_PROPERTY) == SOLR_HTTP_CLIENT_NAME
            assert testProperties.get(SOLR_HTTP_URL_PROPERTY) == solrUrl
    }

    def "it should set the solr zookeeper url when solr mode is set to cloud"() {
        setup:
            String solrUrl = "zookeeper:1234;zookeeper2:1234;zookeeper3:1234"
            minimalConfig.solrMode >> "cloud"
            minimalConfig.solrUrl >> solrUrl
            Properties testProperties
        when:
            preStartSetup.run(minimalConfig)
            testProperties = loadPropFile(systemProps)
        then:
            assert testProperties.get(SOLR_CLIENT_PROPERTY) == SOLR_CLOUD_CLIENT_NAME
            assert testProperties.get(SOLR_CLOUD_URL_PROPERTY) == solrUrl
    }

    def "it should set the cluster name when cluster mode is enabled"() {
        setup:
            String clusterName = "barNode"
            minimalConfig.clusterName >> clusterName
            Properties testProperties
            def keystore
            Certificate cert
            def san
        when:
            preStartSetup.run(minimalConfig)
            testProperties = loadPropFile(systemProps)
            keystore = loadKeystore(keyStorePath)
            cert = keystore.getCertificate(testHostname)
            san = cert.properties.get("subjectAlternativeNames")
        then:
            assert testProperties.get(CLUSTER_NAME_PROPERTY) == clusterName
            assert san.toString().contains(testHostname)
            assert san.toString().contains(clusterName)
    }

    def "it should set the ldap host when ldap is enabled"() {
        setup:
            String ldapHost = "ldapHost"
            minimalConfig.ldapHost >> ldapHost
            Properties testProperties
        when:
            preStartSetup.run(minimalConfig)
            testProperties = loadPropFile(systemProps)
        then:
            assert testProperties.get(LDAP_HOST_PROPERTY) == ldapHost
    }

    private void createSystemFolder(Path systemHome) {
        Path systemLogDir = Paths.get(systemHome.toString(), "data", "log")
        Files.createDirectories(systemLogDir)
        systemLog = Paths.get(systemLogDir.toString(), "system.log")
        Path systemEtcPath = Paths.get(systemHome.toString(), "etc")
        Files.createDirectories(systemEtcPath)
        systemProps = Paths.get(systemEtcPath.toString(), "system.properties")
        systemUserProps = Paths.get(systemEtcPath.toString(), "users.properties")
        systemUserAttr = Paths.get(systemEtcPath.toString(), "users.attributes")
        Path keyStoresDirPath = Paths.get(systemEtcPath.toString(), "keystores")
        Files.createDirectories(keyStoresDirPath)
        keyStorePath = Paths.get(keyStoresDirPath.toString(), "serverKeystore.jks")

        Files.copy(this.getClass().getResourceAsStream('/systemHome/data/log/system.log'), systemLog)
        Files.copy(this.getClass().getResourceAsStream('/systemHome/etc/system.properties'), systemProps)
        Files.copy(this.getClass().getResourceAsStream('/systemHome/etc/users.properties'), systemUserProps)
        Files.copy(this.getClass().getResourceAsStream('/systemHome/etc/users.attributes'), systemUserAttr)
        Files.copy(this.getClass().getResourceAsStream('/systemHome/etc/keystores/serverKeystore.jks'), keyStorePath)
    }

    private Properties loadPropFile(Path propertyFilePath) {
        Properties properties = new Properties()
        InputStream input = null

        try {
            input = new FileInputStream(propertyFilePath.toString())

            properties.load(input)
        } catch (IOException e) {
            e.printStackTrace()
        }

        return properties
    }

    private KeyStore loadKeystore(Path keystorePath) {
        KeyStore keyStore = KeyStore.getInstance('JKS')
        keyStore.load(new FileInputStream(keystorePath.toFile()), DEFAULT_KEYSTORE_PASSWORD.toCharArray())
        return keyStore
    }
}
