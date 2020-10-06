#!/usr/bin/env bats

function setup {
    export ENTRYPOINT_HOME=/opt/entrypoint
    export PATH=${ENTRYPOINT_HOME}/bin:${PATH}
    export APP_HOME=${BATS_TMPDIR}
    mkdir -p ${APP_HOME}/etc
}

function teardown() {
    rm -r ${APP_HOME}/etc/
}

@test "invoking add-registry no arguments prints usage and exits 1" {
  run add-registry
  [ "$status" -eq 1 ]
  [ "${lines[-1]}" = "FATAL ERROR: Not enough positional arguments - we require exactly 1 (namely: 'url'), but got only 0." ]
}

@test "invoking add-registry with required arguments creates a configuration" {
  run add-registry https://foo.bar/baz

  [ "$status" -eq 0 ]
  [ -f "${output}" ]
}

@test "invoking add-registry multiple times with the same registry name will update an existing configuration" {

    original_config=$(add-registry --name foo https://foo.bar/baz)

    run add-registry --name foo https://new.registry.url/

    [ "$status" -eq 0 ]
    [ -f "$output" ]
    [ "$output" == "${original_config}" ]
}
