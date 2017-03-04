package com.github.oconnormi.docker.ddf.entrypoint.config

import org.junit.Rule
import org.junit.rules.TemporaryFolder
import spock.lang.Specification

class AppMetadataSpecification extends Specification {
    @Rule TemporaryFolder tmp
    private String testAppName = "FOO_APP"
    private File testAppHomeFile
    private File testAppLogFile
    private String testAppHome
    private String testAppLog

    private AppMetadata appMetadata

    def setup() {
        testAppHomeFile = tmp.newFolder('foo')
        testAppHome = testAppHomeFile.absolutePath
        testAppLogFile = tmp.newFile('foo.log')
        testAppLog = testAppLogFile.absolutePath
    }

    def "Metadata can be manually specified"() {
        when:
            appMetadata = new AppMetadata(testAppName, testAppHome, testAppLog)
        then:
            assert appMetadata.appName.toString() == testAppName
            assert appMetadata.appHome.toString() == testAppHome
            assert appMetadata.appLog.toString() == testAppLog
    }

    def "Metadata can be specified in the Env vars"() {
        setup: "Create fake set of env vars"
            Map<String, String> env = new HashMap<>()
            env.put(AppMetadata.APP_NAME_ENV_VAR, testAppName)
            env.put(AppMetadata.APP_HOME_ENV_VAR, testAppHome)
            env.put(AppMetadata.APP_LOG_ENV_VAR, testAppLog)
        when:
            appMetadata = new AppMetadata(env)
        then:
            assert appMetadata.appName.toString() == testAppName
            assert appMetadata.appHome.toString() == testAppHome
            assert appMetadata.appLog.toString() == testAppLog
    }
}
