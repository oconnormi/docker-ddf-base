package com.github.oconnormi.docker.ddf.entrypoint

import com.github.oconnormi.docker.ddf.entrypoint.config.EntrypointConfig
import com.github.oconnormi.docker.ddf.entrypoint.PreStartSetup

class Entrypoint {
    private PreStartSetup preStart

    def run(EntrypointConfig config) {
        println config.hostname
        return 0

    }
}

