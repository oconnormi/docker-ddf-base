#!/usr/bin/env bats

function setup {
    export ENTRYPOINT_HOME=/opt/entrypoint
    export APP_HOME=${BATS_TMPDIR}
    mkdir -p ${APP_HOME}/etc
}

function teardown() {
    rm -r ${APP_HOME}/etc/
    unset REGISTRY
}

@test "Invalid registry type file" {
    export REGISTRY="https://foo.bar/baz|foo|fooType"

    run $ENTRYPOINT_HOME/registry.sh

    [ "$status" -eq 1 ]
}

@test "Single registry no optionals" {
    export REGISTRY="https://foo.bar/baz"

    run $ENTRYPOINT_HOME/registry.sh

    file_count=$(ls -1 ${APP_HOME}/etc | wc -l)

    [ "$status" -eq 0 ]
    [ "$file_count" -eq 1 ]
}

@test "Single registry all optionals" {
    export REGISTRY="https://foo.bar/baz|foo|csw|false|false|false|admin|password"

    run $ENTRYPOINT_HOME/registry.sh

    file_count=$(ls -1 ${APP_HOME}/etc | wc -l)

    [ "$status" -eq 0 ]
    [ "$file_count" -eq 1 ]
}

@test "multiple registries no optionals" {

    export REGISTRY="https://foo.bar/baz,https://fake.registry/csw"

    run $ENTRYPOINT_HOME/registry.sh

    file_count=$(ls -1 ${APP_HOME}/etc | wc -l)

    [ "$status" -eq 0 ]
    [ "$file_count" -eq 2 ]
}

@test "multiple registries all optionals" {
    export REGISTRY="https://foo.bar/baz|foo|csw|false|false|false|admin|password,https://fake.registyr/csw|fake|csw|false|true|false|foo|bar"

    run $ENTRYPOINT_HOME/registry.sh

    file_count=$(ls -1 ${APP_HOME}/etc | wc -l)

    [ "$status" -eq 0 ]
    [ "$file_count" -eq 2 ]
}
