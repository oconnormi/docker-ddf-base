#!/usr/bin/env bats

function setup {
    export ENTRYPOINT_HOME=/opt/entrypoint
    export APP_HOME=${BATS_TMPDIR}
    mkdir -p ${APP_HOME}/etc
}
