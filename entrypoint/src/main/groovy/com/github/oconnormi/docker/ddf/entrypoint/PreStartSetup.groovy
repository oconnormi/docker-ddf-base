package com.github.oconnormi.docker.ddf.entrypoint

import static  com.github.oconnormi.docker.ddf.entrypoint.config.Globals.*
import static com.github.oconnormi.docker.ddf.entrypoint.util.Util.loadPropFile

import com.github.oconnormi.docker.ddf.entrypoint.config.EntrypointConfig
import java.nio.file.Paths

class PreStartSetup {

    def run(EntrypointConfig config) {
        Properties systemProperties = loadPropFile(Paths.get(config.appMetadata.appHome.toString(), "etc", "system.properties"))
        setHostname(config, systemProperties)
    }

    private setHostname(EntrypointConfig config, Properties systemProperties) {
        if (systemProperties.get(SYSTEM_HOSTNAME_PROPERTY) != config.hostname) {
            systemProperties.setProperty(SYSTEM_HOSTNAME_PROPERTY, config.hostname)
            systemProperties.store(
                    Paths.get(
                            config.appMetadata.appHome.toString(),
                            "etc",
                            "system.properties").newOutputStream(),
                    null)
        }
    }
}
