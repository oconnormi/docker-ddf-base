#!/usr/bin/env bats

function setup {
    export ENTRYPOINT_HOME=/opt/entrypoint
    export APP_HOME=${BATS_TMPDIR}
    export LOCAL_CERTS_DIR="$APP_HOME/random_dir"

    keystore_dir="/tmp/etc/keystores/"
    test_certs_dir="/opt/entrypoint/test_certs"

    mkdir -p ${APP_HOME}/etc
    mkdir -p $keystore_dir
    mkdir -p $LOCAL_CERTS_DIR

    cp -R $test_certs_dir/demoTruststore $keystore_dir/serverTrustore.jks
}

function teardown() {
    rm -r $LOCAL_CERTS_DIR
    rm -r $keystore_dir
}

@test "invalid directory" {    
    export LOCAL_CERTS_DIR="$APP_HOME/foo"

    run $ENTRYPOINT_HOME/load_local_certs.sh

    [ "$status" -eq 1  ]
    [[ "$output" = *"Invalid directory: $APP_HOME/foo"* ]]
}

@test "no certs" {    
    run $ENTRYPOINT_HOME/load_local_certs.sh
   
    [ "$status" -eq 0  ]
    [[ "$output" = *"0 certificate(s) imported"* ]]
}

@test "one cert" {   
    cp -R $test_certs_dir/foo.pem $LOCAL_CERTS_DIR

    run $ENTRYPOINT_HOME/load_local_certs.sh >&3

    [ "$status" -eq 0  ]
    [[ "$output" = *"1 certificate(s) imported"* ]]
}

@test "multiple certs" {   
    cp -R $test_certs_dir/{foo.pem,bar.pem} $LOCAL_CERTS_DIR

    run $ENTRYPOINT_HOME/load_local_certs.sh >&3

    [ "$status" -eq 0  ]
    [[ "$output" = *"2 certificate(s) imported"* ]]
}

@test "invalid cert" {   
    cp -R $test_certs_dir/bad.pem $LOCAL_CERTS_DIR

    run $ENTRYPOINT_HOME/load_local_certs.sh >&3

    [[ "$output" = *"Failed to import bad"* ]]
}

@test "valid and invalid certs" {   
    cp -R $test_certs_dir/*.pem $LOCAL_CERTS_DIR

    run $ENTRYPOINT_HOME/load_local_certs.sh >&3

    [[ "$output" = *"Failed to import bad"* ]]
    [[ "$output" = *"2 certificate(s) imported"* ]]
}

@test "non .pem files" {   
    cp -R $test_certs_dir/{bar.pem,demoTruststore}  $LOCAL_CERTS_DIR

    run $ENTRYPOINT_HOME/load_local_certs.sh >&3

    [[ "$output" != *"Failed"* ]]
    [[ "$output" = *"1 certificate(s) imported"* ]]
}