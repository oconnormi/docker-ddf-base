#!/bin/bash

_default_config_dir="${APP_HOME}/etc"
_default_profiles_json="${APP_HOME}/etc/ws-security/profiles.json"
_default_in_place_editing=false
_default_hostname=$HOSTNAME

# m4_ignore(
echo "This is just a script template, not the script (yet) - pass it to 'argbash' to fix this." >&2
exit 11  #)Created by argbash-init v2.7.1
# ARG_OPTIONAL_SINGLE([config-directory],[c],[location where the config files are],[${_default_config_dir}])
# ARG_OPTIONAL_SINGLE([profiles-json],[j],[JSON file with profile attributes],[${_default_profiles_json}])
# ARG_OPTIONAL_SINGLE([hostname],[h],[hostname],[${_default_hostname}])
# ARG_OPTIONAL_BOOLEAN([in-place],[i],[replace original config files with edits],[off])
# ARG_POSITIONAL_SINGLE([profile],[p],[security profile to use])
# ARG_DEFAULTS_POS
# ARG_HELP([<The general help message of my script>])
# ARGBASH_GO

# [ <-- needed because of Argbash

trap "exit 1" TERM
export TOP_PID=$$

HOSTNAME=""
PROFILE=""
PROFILE_FILE=""
USER_ATTRIBUTES_FILE=""
ATTRIBUTES_WORKING_FILE=""
CONFIG_WORKING_FILE=""
CONFIG_DIR=""
IN_PLACE_EDITING=""

# Handles printing error messages to the terminal and exiting the program.
# ${1} - String of the error message to print
function error() {
    clean_up true
    echo "error: ${1}" 1>&2
    kill -s TERM $TOP_PID
}

# Handles checking the global variables used to hold the program arguments and throws the appropriate error.
function check_program_args() {
    if [[ $HOSTNAME = "" ]]; then
        error "Hostname variable is not set."
    fi

    if [[ ! -d $CONFIG_DIR ]]; then
        error "Unable to find the config directory: '${CONFIG_DIR}'"
    elif [[ ! -f $PROFILE_FILE ]]; then
        error "Unable to find the security profile JSON file."
    elif [[ ! -f $USER_ATTRIBUTES_FILE ]]; then
        error "Unable to find the user attributes file."
    fi

    # does a basic parse on the profiles JSON file to check that it is in valid JSON format
    profile_json=$(jq '.' $PROFILE_FILE)
    if [[ $? != 0 ]]; then
        error "Unable to parse the profiles JSON file."
    fi

    available_profiles=$(find_available_profile_names)
    is_valid_profile=false
    # checks if the inputted profile name is in the array of available profiles
    for profile in $available_profiles; do
        if [[ $PROFILE = $profile ]]; then
            is_valid_profile=true
            break
        fi
    done

    if [[ $is_valid_profile = false ]]; then
        error "Invalid security profile name: '${PROFILE}'"
    fi
}

# Set up function to be run at the beginning that handles setting the global variables defining
# file locations and command-line arguments.
function set_up() {
    HOSTNAME=$_arg_hostname
    PROFILE=$_arg_profile
    CONFIG_DIR=$_arg_config_directory
    PROFILE_FILE=$_arg_profiles_json
    USER_ATTRIBUTES_FILE="${_arg_config_directory}/user.attributes"
    # in-place editing value will be either "on" or "off"
    IN_PLACE_EDITING=${_arg_in_place}

    # calls function to check that the program arguments are valid
    check_program_args

    CONFIG_WORKING_FILE="./config_tmp_working.config"
    touch $CONFIG_WORKING_FILE
    # jq doesn't do in-place editing so we have to create a temporary working file to make our
    # modifications in
    ATTRIBUTES_WORKING_FILE="./jq_tmp_working.json"
    # use the current user attributes file as a starting point for the working file
    cp $USER_ATTRIBUTES_FILE $ATTRIBUTES_WORKING_FILE
}

# Clean up function to be run at the end that handles removing any temporary files created during
# the script's operation.
# ${1} - Boolean of if this function was called from an error function.
function clean_up() {
    # only do modification tasks if clean_up function called from the main function
    if [[ ${1} = false ]]; then
        if [[ $IN_PLACE_EDITING = "on" ]]; then
            cp $ATTRIBUTES_WORKING_FILE $USER_ATTRIBUTES_FILE
        else
            printf "\nModified ${USER_ATTRIBUTES_FILE}:\n"
            jq '.' $ATTRIBUTES_WORKING_FILE
        fi
    fi

    if [[ -f $ATTRIBUTES_WORKING_FILE ]]; then
        rm $ATTRIBUTES_WORKING_FILE
    fi

    if [[ -f $CONFIG_WORKING_FILE ]]; then
        rm $CONFIG_WORKING_FILE
    fi
}

# Parses the profiles JSON file and finds the available profile names.
function find_available_profile_names() {
    profiles=$(jq -r 'keys | .[]' $PROFILE_FILE)
    echo $profiles
}

# Helper function to iterate through each attribute of the current property group of the selected
# profile and sets the key-value in the user attributes file.
# ${1} - Base64-encoded array of key-value pairings of attributes
# ${2} - Name of key to set the attributes for
# ${3} - Boolean of if the key of the object to be modified already exists in the current user
#        attributes file
function set_attributes() {
    if [[ ${3} != true ]]; then
        # jq doesn't do in-place editing when setting values so we have to keep track of our
        # modifications in an object variable
        working_obj=$(jq --arg attr_key ${2} '.[ $attr_key ] = {}' $ATTRIBUTES_WORKING_FILE)
    else
        # throws an error if the given key does not actually exist in the user attributes file
        if [[ $(jq --arg attr_key ${2} '.[ $attr_key ]' $ATTRIBUTES_WORKING_FILE) = "null" ]]; then
            error "Key '${2}' does not exist in the user attributes file."
        fi

        # don't need to assign a new key object so use the original unmodified JSON
        working_obj=$(jq '.' $ATTRIBUTES_WORKING_FILE)
    fi

    # decodes the given array and compacts the output so we can loop through it and get each key
    # and associated value
    for attribute in $(echo ${1} | base64 --decode | jq -c '.[]'); do
        property_key=$(echo $attribute | jq -r '.key')
        property_value=$(echo $attribute | jq -r '.value')
        # array values need to be handled differently than strings
        if [[ $(echo $attribute | jq -r '.value | type') = "array" ]]; then
            # initializes an array to hold the property values for the current attribute
            working_obj=$(echo $working_obj | jq -r --arg attr_key ${2} --arg key $property_key \
                    '.[ $attr_key ][ $key ] = []')
            # iterates through the values in the array of property values and appends each to the
            # array created for the current attribute
            for arr_val in $(echo $property_value | jq -r '.[]'); do
                working_obj=$(echo $working_obj | jq -r --arg attr_key ${2} --arg key $property_key \
                    --arg value $arr_val '.[ $attr_key ][ $key ] += [ $value ]')
            done
        else
            # sets the current attribute and reassigns the output to the tracked working object variable
            working_obj=$(echo $working_obj | jq -r --arg attr_key ${2} --arg key $property_key \
                    --arg value $property_value '.[ $attr_key ][ $key ] = $value')
        fi
    done

    # return the base64 encoded working object variable with all the new attributes
    echo $(echo $working_obj | jq -r '@base64')
}

# Sets the properties for the designated config files.
# ${1} - Base64-encoded array of config properties
function set_config_properties() {
    # iterates through the config objects and sets the properties in the specified locations
    # we have to base64 encode the config objects to prevent jq from wrapping the whitespaces with
    # single quotes and causing the parser to break
    for config in ${1}; do
        pid=$(echo $config | base64 --decode | jq -r '.value.pid')
        properties=$(echo $config | base64 --decode | jq -r '.value.properties | to_entries')
        config_file="${CONFIG_DIR}/${pid}.config"

        if [[ -f $config_file ]]; then
            cp $config_file $CONFIG_WORKING_FILE

            for property in $(echo $properties | jq -r '.[] | @base64'); do
                property_key=$(echo $property | base64 --decode | jq -r '.key')
                property_value=$(echo $property | base64 --decode | jq -rc '.value')
                # use oconnormi's props command line tool for editing config files
                props set $property_key "$property_value" $CONFIG_WORKING_FILE
            done

            if [[ $IN_PLACE_EDITING = "on" ]]; then
                cp $CONFIG_WORKING_FILE $config_file
            else
                printf "\nModified ${config_file}:\n"
                cat $CONFIG_WORKING_FILE
            fi
        fi
    done
}

# Parses the JSON object for the selected security profile and gets the groups of properties
# ${1} - Base64-encoded JSON object with the properties of the selected profile
function set_profile_properties() {
    decoded_profile_attributes=$(echo ${1} | base64 --decode)
    guest_claims=$(echo $decoded_profile_attributes | jq -r '.guestClaims | to_entries | @base64')
    system_claims=$(echo $decoded_profile_attributes | jq -r '.systemClaims | to_entries | @base64')
    configs=$(echo $decoded_profile_attributes | jq -r '.configs | to_entries | .[] | @base64')

    # writes the final modified objects to the working file
    echo $(echo $(set_attributes $guest_claims "guest" false) | base64 --decode | jq '.') \
            > $ATTRIBUTES_WORKING_FILE
    echo $(echo $(set_attributes $system_claims $HOSTNAME true) | base64 --decode | jq '.') \
            > $ATTRIBUTES_WORKING_FILE

    # sets the config properties defined separately from the claims attributes
    echo $(set_config_properties $configs)
}

# Main function to run when the script is started.
function main() {
    set_up
    profile_attributes=$(jq -r --arg key $PROFILE '.[ $key ] | @base64' $PROFILE_FILE)
    set_profile_properties $profile_attributes
    clean_up false
}

main

# ] <-- needed because of Argbash
