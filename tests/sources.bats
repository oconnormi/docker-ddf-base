#!/usr/bin/env bats

function setup {
    export APP_HOME=${BATS_TMPDIR}
    mkdir -p ${APP_HOME}/etc
}

function teardown() {
    rm -r ${APP_HOME}/etc/
}

@test "Test template file is invalid" {    
    export SOURCES="templateName|testName1|testUrl"
    run $ENTRYPOINT_HOME/sources.sh

    [ "$status" -eq 1 ]
    [[ "$output" = *"Template file templateName.config could not be found in path"* ]]
}

@test "Test file is generated" {
    export SOURCES="csw_federated|testName2|testUrl"
    run $ENTRYPOINT_HOME/sources.sh
    files="$(ls -1 ${APP_HOME}/etc | wc -l)"

    [ "${lines[0]}" == "Creating DDF Catalog source configuration with arguments: --config-directory /tmp/etc --template-directory /opt/entrypoint/templates/sources --url testUrl csw_federated testName2" ]
    [[ "${lines[-2]}" = *"Configuration file "*" created in "*" seconds"* ]]
}

@test "Test correct filename" {
    regex="\w*-\b[0-9a-f]{8}\b-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-\b[0-9a-f]{12}\b/i"
    
    export SOURCES="csw_federated|testName3|testUrl"
    run $ENTRYPOINT_HOME/sources.sh
    list="$(ls ${APP_HOME}/etc)"

    [ "$status" -eq 0  ]
    [[ ! "$list" =~ $regex ]]
}

@test "Test multiple files are created" {
    export SOURCES="csw_federated|testName4|1.com,csw_federated|testName4.1|https://2.com,csw_federated|testName4.2|3.net"
    run $ENTRYPOINT_HOME/sources.sh
    files="$(ls -1 ${APP_HOME}/etc | wc -l)"

    [ "$status" -eq 0  ]
    [[ "$output" = *"Total number of files created: 3"* ]]
}