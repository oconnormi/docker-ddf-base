package com.github.oconnormi.docker.ddf.entrypoint

import com.github.oconnormi.docker.ddf.entrypoint.config.EntrypointConfig

class Entrypoint {
    private PreStartSetup preStart
    private PostStartSetup postStart

    def run(EntrypointConfig config) {
        preStart.run(config)

        postStart.run(config)
    }
}

