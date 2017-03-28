package com.github.oconnormi.docker.ddf.entrypoint

import static  com.github.oconnormi.docker.ddf.entrypoint.config.Globals.*
import static com.github.oconnormi.docker.ddf.entrypoint.util.Util.deleteJsonProperty
import static com.github.oconnormi.docker.ddf.entrypoint.util.Util.loadJsonPropFile
import static com.github.oconnormi.docker.ddf.entrypoint.util.Util.updateJsonProperty
import static com.github.oconnormi.docker.ddf.entrypoint.util.Util.updateProperty
import static com.github.oconnormi.docker.ddf.entrypoint.util.Util.deleteProperty

import com.github.oconnormi.docker.ddf.entrypoint.config.EntrypointConfig
import java.nio.file.Paths

class PreStartSetup {

    def run(EntrypointConfig config) {
        setHostname(config)
        updateSystemUser(config)
    }

    private setHostname(EntrypointConfig config) {
        updateProperty(Paths.get(config.appMetadata.appHome.toString(), "etc", "system.properties"),
                SYSTEM_HOSTNAME_PROPERTY, config.hostname)
    }

    private updateSystemUser(EntrypointConfig config) {
        deleteProperty(Paths.get(config.appMetadata.appHome.toString(), "etc", "users.properties"), DEFAULT_SYSTEM_USER)
        updateProperty(Paths.get(config.appMetadata.appHome.toString(), "etc", "users.properties"), config.hostname,
                "${config.hostname},${SYSTEM_USER_ROLES}")
        Map map = loadJsonPropFile(Paths.get(config.appMetadata.appHome.toString(), "etc", "users.attributes")).get(DEFAULT_SYSTEM_USER) as Map
        map.put("http://schemas.xmlsoap.org/ws/2005/05/identity/claims/emailaddress", "system@${config.hostname}")
        deleteJsonProperty(Paths.get(config.appMetadata.appHome.toString(), "etc", "users.attributes"), DEFAULT_SYSTEM_USER)

        updateJsonProperty(Paths.get(config.appMetadata.appHome.toString(), "etc", "users.attributes"), config.hostname, map)
    }
}
