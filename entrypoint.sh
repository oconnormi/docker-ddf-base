#!/bin/bash

# Initialize ENTRYPOINT_HOME
ENTRYPOINT_HOME=""
ENTRYPOINT_LIBRARY=""
ENTRYPOINT_ENV_LIBRARY=""
ENTRYPOINT_BIN=""

function initScriptDir {
  case "`uname`" in
    Darwin*)
      darwin=true
      ;;
    Linux*)
      linux=true
      ;;
    *)
      echo -e "\n`uname` is not currently supported, attempting to run with settings for linux\n"
      linux=true
  esac

  # Set ENTRYPOINT_HOME based on environment
  if $linux; then
  	ENTRYPOINT_HOME="$(dirname "$(readlink -f "$0")")"
  elif $darwin; then
  	#For Darwin, check for greadlink
  	if type -p greadlink; then
  		ENTRYPOINT_HOME="$(dirname "$(greadlink -f "$0")")"
  	else
  		echo -e "\n greadlink is not available in the PATH\n\
  			This is provided on OSX by coreutils\n\
  			coreutils can be installed through homebrew by running\n\
  			'brew install coreutils'\n\
  			For more information on homebrew, see: http://brew.sh"
  		echo -e "\nAttempting fallback method...\n"

  		ENTRYPOINT_HOME=$( cd "$( dirname "$0" )" && pwd )
    fi
  fi
}

function initEnvironment {
  for env in ${ENTRYPOINT_ENV_LIBRARY}/*
  do
    source $env
  done
}


function entrypoint {
  if [ -e "${ENTRYPOINT_LIBRARY}/pre_start.sh" ]; then
    echo "Pre-Start Configuration Script found, running now..."
    if [ $UID = 0 ]; then
      chmod 755 ${ENTRYPOINT_LIBRARY}/pre_start.sh
    else
      sudo chmod 755 ${ENTRYPOINT_LIBRARY}/pre_start.sh
    fi
    sleep 1
    ${ENTRYPOINT_LIBRARY}/pre_start.sh
  fi
  
  echo "Starting ${APP_NAME}"
  
  if [ -n "$HTTPS_PORT" ] && [ "$HTTPS_PORT" -lt "1024" ] && [ $EUID -ne 0 ]; then
    sudo $APP_HOME/bin/start
  else
    env -i $APP_HOME/bin/start
  fi
  
  sleep 2
  
  if [ -e "${ENTRYPOINT_LIBRARY}/post_start.sh" ]; then
    echo "Post-Start Configuration Script found, running now..."
    if [ $UID = 0 ]; then
      chmod 755 ${ENTRYPOINT_LIBRARY}/post_start.sh
    else
      sudo chmod 755 ${ENTRYPOINT_LIBRARY}/post_start.sh
    fi 
    sleep 1
    ${ENTRYPOINT_LIBRARY}/post_start.sh
  fi
  
  tail -f $APP_LOG
}

function main {
  initScriptDir $@
  export ENTRYPOINT_HOME
  export ENTRYPOINT_LIBRARY=${ENTRYPOINT_HOME}/library
  export ENTRYPOINT_ENV_LIBRARY=${ENTRYPOINT_HOME}/environment
  export ENTRYPOINT_BIN=${ENTRYPOINT_HOME}/bin
  export PATH=${ENTRYPOINT_BIN}:${PATH}
  initEnvironment $@
  entrypoint $@
}

main $@
