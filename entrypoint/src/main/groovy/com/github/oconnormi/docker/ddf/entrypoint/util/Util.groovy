package com.github.oconnormi.docker.ddf.entrypoint.util

import static org.boon.Boon.toPrettyJson

import org.apache.commons.configuration.PropertiesConfiguration
import org.apache.commons.configuration.PropertiesConfigurationLayout
import org.boon.json.JsonFactory
import org.boon.json.ObjectMapper

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

static void updateProperty(Path propertyFilePath, String key, String value) {
    PropertiesConfiguration properties = new PropertiesConfiguration()
    PropertiesConfigurationLayout layout = new PropertiesConfigurationLayout(properties)
    layout.load(new InputStreamReader(propertyFilePath.newInputStream()))

    properties.setProperty(key, value)
    layout.save(propertyFilePath.newWriter(false))
}

static void deleteProperty(Path propertyFilePath, String key) {
    PropertiesConfiguration properties = new PropertiesConfiguration()
    PropertiesConfigurationLayout layout = new PropertiesConfigurationLayout(properties)
    layout.load(new InputStreamReader(propertyFilePath.newInputStream()))

    properties.clearProperty(key)
    layout.save(propertyFilePath.newWriter(false))
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

static Map loadJsonPropFile(Path jsonFilePath) {
    ObjectMapper MAPPER = JsonFactory.create();
    Map<String, Object> json = null
    json = MAPPER.parser().parseMap(jsonFilePath.newInputStream())
    return json
}

static updateJsonProperty(Path jsonFilePath, String key, Object value) {

    Map<String, Object> json = loadJsonPropFile(jsonFilePath)
    json.put(key, value)
    jsonFilePath.write(toPrettyJson(json))

}

static deleteJsonProperty(Path jsonFilePath, String key) {

    Map<String, Object> json = loadJsonPropFile(jsonFilePath)
    json.remove(key)

    jsonFilePath.write(toPrettyJson(json))
}
