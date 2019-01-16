#!/bin/bash

# This script uses templates in order to generate configurations for external sources
# bin/argbash-init --pos source-type --pos source-name --opt username --opt password --opt url --opt config-directory --opt template-directory create-source.m4

# m4_ignore(
echo "This is just a script template, not the script (yet) - pass it to 'argbash' to fix this." >&2
exit 11  #)Created by argbash-init v2.5.0
# ARG_OPTIONAL_SINGLE([username], , [Credentials for the source])
# ARG_OPTIONAL_SINGLE([password], , [Credentials for the source])
# ARG_OPTIONAL_SINGLE([url], , [the source's address])
# ARG_OPTIONAL_SINGLE([config-directory], , [location where the configuration file will be created])
# ARG_OPTIONAL_SINGLE([template-directory], , [location ofthe template file used to make the config])
# ARG_POSITIONAL_SINGLE([source-type], [The template that will be used to generate the source configuration], )
# ARG_POSITIONAL_SINGLE([source-name], [Desired name for the source], )
# ARG_HELP([Create a source configuration file])
# ARGBASH_GO

# [
start_time=`date +%s`

if [ -z "$_arg_source_type" ]; then
  echo "No arguments supplied!"; exit 1;
fi

url=$_arg_url
config_dir=${_arg_config_directory%/}
template_dir=${_arg_template_directory:="source_templates"}
$template_dir=${template_dir%/}
config=$_arg_source_type
name=$_arg_source_name
password=$_arg_password

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

uuid=$(generateConfigUUID)
pid=$(generateServicePid)
file_name="$config-$uuid.config"

if [ -e $file_name ]; then
  echo "File $file_name already exists!" >&2; exit 1
else
  
  export name
  export username
  export password
  export url
  export pid

  if [ ! -f "$template_dir/$config.config" ]; then
    echo "Template file $config.config could not be found in path $template_dir." >&2; exit 1
  fi

  if [ -d "$config_dir" ]; then
    echo "File $config.config cannot be created in $config_dir, since the directory does not exist." >&2; exit 1
  fi

  envsubst < "$template_dir/$config.config" > "$config_dir/$file_name"

  end_time=`date +%s`
  echo
  echo "Configuration file $config_dir/$file_name created in $((end_time-start_time)) seconds"
fi
# ]