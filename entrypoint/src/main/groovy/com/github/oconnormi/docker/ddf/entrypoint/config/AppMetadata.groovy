package com.github.oconnormi.docker.ddf.entrypoint.config

import java.nio.file.Path
import java.nio.file.Paths

/**
 * Global Metadata Items obtained from the Container Environment
 *
 */
class AppMetadata {
    public static final APP_NAME_ENV_VAR = "APP_NAME"
    public static final APP_HOME_ENV_VAR = "APP_HOME"
    public static final APP_LOG_ENV_VAR = "APP_LOG"

    private String appName
    private Path appHome
    private Path appLog

    /**
     * Global Metadata for container entrypoint
     * @param appName - Application name used for branding
     * @param appHome - Application Home directory
     * @param appLog - Application Log file
     */
    AppMetadata(String appName, Path appHome, Path appLog) {
        this.appName = appName
        this.appHome = appHome
        this.appLog = appLog
    }

    /**
     * Global Metadata for container entrypoint
     * @param appName - Application name used for branding
     * @param appHome - Application Home directory
     * @param appLog - Application Log file
     */
    AppMetadata(String appName, String appHome, String appLog) {
        this.appName = appName
        this.appHome = Paths.get(appHome)
        this.appLog = Paths.get(appLog)
    }

    /**
     * Global Metadata for container entrypoint
     * @param env - map containing container's environment variables
     */
    AppMetadata(Map<String, String> env) {
        this.appName = env[APP_NAME_ENV_VAR]
        this.appHome = Paths.get(env[APP_HOME_ENV_VAR])
        this.appLog = Paths.get(env[APP_LOG_ENV_VAR])
    }

    String getAppName() {
        return appName
    }

    void setAppName(String appName) {
        this.appName = appName
    }

    Path getAppHome() {
        return appHome
    }

    void setAppHome(Path appHome) {
        this.appHome = appHome
    }

    void setAppHome(String appHome) {
        this.appHome = Paths.get(appHome)
    }

    Path getAppLog() {
        return appLog
    }

    void setAppLog(Path appLog) {
        this.appLog = appLog
    }

    void setAppLog(String appLog) {
        this.appLog = Paths.get(appLog)
    }
}
