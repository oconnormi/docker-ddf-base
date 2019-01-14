#!/bin/bash

# This script uses templates in order to generate configurations for external sources
# bin/argbash-init --pos source-type --pos source-name --pos username --pos password --opt url --opt directory cool-config.m4

# m4_ignore(
echo "This is just a script template, not the script (yet) - pass it to 'argbash' to fix this." >&2
exit 11  #)Created by argbash-init v2.5.0
# ARG_OPTIONAL_SINGLE([url], , [the source's address])
# ARG_OPTIONAL_SINGLE([directory], , [directory location where the configuration file will be created])
# ARG_POSITIONAL_SINGLE([source-type], [Input a single digit number 1-6], )
# ARG_POSITIONAL_SINGLE([source-name], [Desired name for the source], )
# ARG_POSITIONAL_SINGLE([username], [Credentials for the source], )
# ARG_POSITIONAL_SINGLE([password], [Credentials for the source], )
# ARG_HELP([Create a source configuration file.])
# ARGBASH_GO

# [
start_time=`date +%s`

if [ -z "$_arg_source_type" ]; then
  echo "No arguments supplied!"; exit 1;
fi

url=$_arg_url
directory=$_arg_directory
config=$_arg_source_type
name=$_arg_source_name
password=$_arg_password

config_1="DDMS_MDC_JSON_Service"
config_2="MDF_JSON_Connected_Source"
config_3="1.3_SOAP_Connected_Source"
config_4="DDMS_SOAP_Service"
config_5="2.0_MDC_Connected_Source"
config_6="2.0_MDC_Query_Service"
regex="^[1-6]+$"

function generateConfigUUID() {
  cat /dev/urandom | LC_CTYPE=C tr -dc "a-f0-9" | fold -w 32 | head -n 1
}

function generateServicePid() {
  echo "${_cdm_pid}$(cat /dev/urandom | LC_CTYPE=C tr -dc 'a-f0-9' | fold -w 8 | head -n 1)\
-$(cat /dev/urandom | LC_CTYPE=C tr -dc 'a-f0-9' | fold -w 4 | head -n 1)\
-$(cat /dev/urandom | LC_CTYPE=C tr -dc 'a-f0-9' | fold -w 4 | head -n 1)\
-$(cat /dev/urandom | LC_CTYPE=C tr -dc 'a-f0-9' | fold -w 4 | head -n 1)\
-$(cat /dev/urandom | LC_CTYPE=C tr -dc 'a-f0-9' | fold -w 12 | head -n 1)"
}
 
if  [[ ! $config =~ $regex ]] ; then
  echo "error: Invalid input" >&2; exit 1
  else
    case $config in
      "1") config=$config_1 ;;
      "2") config=$config_2 ;;
      "3") config=$config_3 ;;
      "4") config=$config_4 ;;
      "5") config=$config_5 ;;
      "6") config=$config_6 ;;
    esac
fi

uuid=$(generateConfigUUID)
pid=$(generateServicePid)
file_name="$config-$uuid.config"

if [ -e $file_name ]; then
  echo "File $file_name already exists!" >&2; exit 1
else
  # ensure $directory ends with a '/'  
  if [ ! -z "$directory" ]; then
    if [[ "$directory" != */ ]]; then    
      $directory="$directory/"
    fi  
  fi 
  
  export directory
  export name
  export username
  export password
  export url
  export pid
  export uuid

  if [ ! -f "source_templates/$config.config" ]; then
    echo "Template file $config.config could not be found." >&2; exit 1
  fi

  envsubst < "source_templates/$config.config" > "$directory$file_name"
  
  end_time=`date +%s`
  echo
  echo "Configuration file $file_name in path $directory created in $((end_time-start_time))s"
fi
# ]