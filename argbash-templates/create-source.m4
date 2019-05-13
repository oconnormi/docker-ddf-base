#!/bin/bash

_source_templates_directory=${SOURCE_TEMPLATES_DIRECTORY:=$ENTRYPOINT_HOME/templates/sources}
_default_config_directory=${APP_HOME}/etc

# This script uses templates in order to generate configurations for external sources
# bin/argbash-init --pos source-type --pos source-name --opt username --opt password --opt url --opt config-directory --opt template-directory create-source.m4

# m4_ignore(
echo "This is just a script template, not the script (yet) - pass it to 'argbash' to fix this." >&2
exit 11  #)Created by argbash-init v2.5.0
# ARG_OPTIONAL_SINGLE([username], [u], [Credentials for the source])
# ARG_OPTIONAL_SINGLE([password], [p], [Credentials for the source])
# ARG_OPTIONAL_SINGLE([url], , [the source's address])
# ARG_OPTIONAL_SINGLE([config-directory], [c], [location where the configuration file will be created], [${_default_config_directory}])
# ARG_OPTIONAL_SINGLE([template-directory], [t], [location of the template file used to make the config], [${_source_templates_directory}])
# ARG_POSITIONAL_SINGLE([source-type], [The template that will be used to generate the source configuration])
# ARG_POSITIONAL_SINGLE([source-name], [Desired name for the source])
# ARG_HELP([Create a source configuration file])
# ARGBASH_GO

# [
start_time=`date +%s`

if [ -z "$_arg_source_type" ]; then
  echo "No arguments supplied!"; exit 1;
fi

url=$_arg_url
config_dir=${_arg_config_directory%/}
template_dir=${_arg_template_directory%/}
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
  
  export name username password url pid

  if [ ! -f "$template_dir/$config.config" ]; then
    echo "Template file $config.config could not be found in path $template_dir." >&2; exit 1
  fi

  if [ ! -d "$config_dir" ]; then
    echo "File $config.config cannot be created in $config_dir, since the directory does not exist." >&2; exit 1
  fi

  echo "Attempting to create source configuration file $config.config with the following arguments"
  echo "name: $name"
  echo "url: $url"
  echo "username: $username"

  envsubst < "$template_dir/$config.config" > "$config_dir/$file_name"

  unset name username password url pid

  end_time=`date +%s`
  echo "Configuration file $config_dir/$file_name created in $((end_time-start_time)) seconds"
fi
# ]