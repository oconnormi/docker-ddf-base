#!/usr/bin/env bats

function setup {
    export ENTRYPOINT_HOME=/opt/entrypoint
    export LIBRARY_HOME=${ENTRYPOINT_HOME}/library
    export PATH=${ENTRYPOINT_HOME}/bin:${PATH}
    export APP_HOME=${BATS_TMPDIR}
    mkdir -p ${APP_HOME}/etc
}

function teardown() {
    rm -r ${APP_HOME}/etc/
    unset REGISTRY
}

@test "Invalid registry type file" {
    export REGISTRY="https://foo.bar/baz|foo|fooType"

    run $LIBRARY_HOME/registry.sh

    [ "$status" -eq 1 ]
}

@test "Single registry no optionals" {
    export REGISTRY="https://foo.bar/baz"

    run $LIBRARY_HOME/registry.sh

    file_count=$(ls -1 ${APP_HOME}/etc | wc -l)

    [ "$status" -eq 0 ]
    [ "$file_count" -eq 1 ]
}

@test "Single registry all optionals" {
    export REGISTRY="https://foo.bar/baz|foo|csw|false|false|false|admin|password"

    run $LIBRARY_HOME/registry.sh

    file_count=$(ls -1 ${APP_HOME}/etc | wc -l)

    [ "$status" -eq 0 ]
    [ "$file_count" -eq 1 ]
}

@test "multiple registries no optionals" {

    export REGISTRY="https://foo.bar/baz,https://fake.registry/csw"

    run $LIBRARY_HOME/registry.sh

    file_count=$(ls -1 ${APP_HOME}/etc | wc -l)
    echo "file count: ${file_count}" >&3
    echo "Output: ${output}" >&3

    [ "$status" -eq 0 ]
    [ "$file_count" -eq 2 ]
}

@test "multiple registries all optionals" {
    export REGISTRY="https://foo.bar/baz|foo|csw|false|false|false|admin|password,https://fake.registyr/csw|fake|csw|false|true|false|foo|bar"

    run $LIBRARY_HOME/registry.sh

    file_count=$(ls -1 ${APP_HOME}/etc | wc -l)

    [ "$status" -eq 0 ]
    [ "$file_count" -eq 2 ]
}
