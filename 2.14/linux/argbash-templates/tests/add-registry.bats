#!/usr/bin/env bats

function setup {
    export ENTRYPOINT_HOME=/opt/entrypoint
    export APP_HOME=${BATS_TMPDIR}
    mkdir -p ${APP_HOME}/etc
}

@test "invoking add-registry no arguments prints usage and exits 1" {
  run add-registry
  [ "$status" -eq 1 ]
  [ "${lines[-1]}" = "FATAL ERROR: Not enough positional arguments - we require exactly 1 (namely: 'url'), but got only 0." ]
}