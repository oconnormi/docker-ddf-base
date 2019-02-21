#!/usr/bin/env bats

function setup() {
    create_test_profiles_json
}

function teardown() {
    if [[ -f jq_tmp_working.json ]]; then
        rm jq_tmp_working.json
    fi

    if [[ -f test_guest_attributes.json ]]; then
        rm test_guest_attributes.json
    fi

    output=""
}

# Creates a JSON file with dummy data to use for tests.
function create_test_profiles_json() {
    test_json_str='{"PROFILE_A":{"guestClaims":{"guest1":"profile-a-guest-1","guest2":"profile-a-guest-2","guest3":"profile-a-guest-3"},"systemClaims":{"system1":"profile-a-system-1","system2":"profile-a-system-2","system3":"profile-a-system-3"},"configs":[{"pid":"test1.pid","properties":{"prop1":"foo-a","prop2":"bar-a","prop3":"baz-a"}},{"pid":"test2.pid","properties":["prop1=a","prop2=a","prop3=a"]}]},"PROFILE_B":{"guestClaims":{"guest1":"profile-b-guest-1","guest2":"profile-b-guest-2","guest3":"profile-b-guest-3"},"systemClaims":{"system1":"profile-b-system-1","system2":"profile-b-system-2","system3":"profile-b-system-3"},"configs":[{"pid":"test1.pid","properties":{"prop1":"foo-b","prop2":"bar-b","prop3":"baz-b"}},{"pid":"test2.pid","properties":["prop1=b","prop2=b","prop3=b"]}]},"PROFILE_C":{"guestClaims":{"guest1":"profile-c-guest-1","guest2":"profile-c-guest-2","guest3":"profile-c-guest-3"},"systemClaims":{"system1":"profile-c-system-1","system2":"profile-c-system-2","system3":"profile-c-system-3"},"configs":[{"pid":"test1.pid","properties":{"prop1":"foo-c","prop2":"bar-c","prop3":"baz-c"}},{"pid":"test2.pid","properties":["prop1=c","prop2=c","prop3=c"]}]}}'
    echo $test_json_str > test_guest_attributes.json
}

@test "invalid security profile argument" {
    run set-guest-attributes foo

    [ "$status" -eq 1 ]
    [[ "${output}" = *"Invalid security profile name: 'foo'"* ]]
}

@test "invalid hostname argument" { 
    run set-guest-attributes NIPR -h foo

    [[ "${output}" = *"Key 'foo' does not exist in the user attributes file."* ]]
}

@test "profiles JSON file does not exist" {
    run set-guest-attributes NIPR -j foo.json

    [ "$status" -eq 1 ]
    [[ "${output}" = *"Unable to find the security profile JSON file."* ]]
}

@test "config directory does not exist" {
    run set-guest-attributes JWICS -c foo/

    [ "$status" -eq 1 ]
    [[ "${output}" = *"Unable to find the config directory: 'foo/'"* ]]
}
