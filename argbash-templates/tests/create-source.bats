#!/usr/bin/env bats

function setup {
    export ENTRYPOINT_HOME=/opt/entrypoint
    export PATH=${ENTRYPOINT_HOME}/bin:${PATH}
    export APP_HOME=${BATS_TMPDIR}
    mkdir -p ${APP_HOME}/etc
}

@test "Test missing parameters" {
    run create-source

    [ "$status" -eq 1 ]
    [[ "$output" = *"Not enough positional arguments"* ]]

    output=""
    run create-source "--source-type Mike"
    [ "$status" -eq 1 ]
    [[ "$output" = *"Not enough positional arguments"* ]]

    output=""
    run create-source "--source-name Dang"
    [ "$status" -eq 1 ]
    [[ "$output" = *"Not enough positional arguments"* ]]
}

@test "Test empty/null parameters" {
    run create-source "--source-type Mike --source-name     "
    [ "$status" -eq 1 ]
    [[ "$output" = *"Not enough positional arguments"* ]]

    output=""
    run create-source "---source-type     --source-name  Rita   "
    [ "$status" -eq 1 ]
    [[ "$output" = *"Not enough positional arguments"* ]]
}

@test "Test invalid parameters" {
    run create-source "--source-type Anthony --source name     "

    [ "$status" -eq 1 ]
    [[ "$output" = *"Not enough positional arguments"* ]]

    output=""
    run create-source "--source-type Anthony --source name  nanme "

    [ "$status" -eq 1 ]
    [[ "$output" = *"Not enough positional arguments"* ]]

    output=""
    run create-source "---source-type     --source-name  Mike   "
    
    [ "$status" -eq 1 ]
    [[ "$output" = *"Not enough positional arguments"* ]]
}
