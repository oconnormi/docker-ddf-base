package com.github.oconnormi.docker.ddf.entrypoint.util

import java.nio.file.Path

/**
 * Execute an External Command
 * @param command
 * @param workingDir
 * @return
 */
static executeCommand(String command, Path workingDir) {
    println "Running Command: ${command}"
    Process process = new ProcessBuilder(addShellPrefix(command))
            .directory(workingDir.toFile())
            .redirectErrorStream(true)
            .start()
    process.waitFor()

    return [process.exitValue(), process.getInputStream().text]
}

/**
 * inserts a shell prefix before a command
 */
static String[] addShellPrefix(String command) {
    String[] commandArray = new String[3]
    commandArray[0] = "sh"
    commandArray[1] = "-c"
    commandArray[2] = command
    return commandArray
}

static Properties loadPropFile(Path propertyFilePath) {
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
