#!/usr/bin/env bats

function setup() {
    # @TODO
    echo "Starting tests!"
}

function teardown() {
    if [[ -f jq_tmp_working.json ]]; then
        rm jq_tmp_working.json
    fi

    output=""
}

@test "invalid security profile argument" {
    run ./guest.sh dib1.squirtle.local foo

    [ "$status" -eq 1 ]
    [[ "${output}" = *"Invalid security profile name: 'foo'"* ]]
}

@test "invalid hostname argument" {
    run ./guest.sh foo NIPR

    # @TODO - fix status code
    # [ "$status" -eq 1 ]
    [[ "${output}" = *"Key 'foo' does not exist in the user attributes file."* ]]
}

@test "profiles JSON file does not exist" {
    run ./guest.sh dib1.squirtle.local NIPR -p foo.json

    [ "$status" -eq 1 ]
    [[ "${output}" = *"Unable to find the security profile JSON file."* ]]
}

@test "config directory does not exist" {
    run ./guest.sh dib1.squirtle.local JWICS -c foo/

    [ "$status" -eq 1 ]
    [[ "${output}" = *"Unable to find the config directory: 'foo/'"* ]]
}
