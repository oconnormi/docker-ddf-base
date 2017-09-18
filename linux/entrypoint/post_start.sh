#!/bin/bash

echo -n "Waiting for log file: ${APP_LOG} to be created..."
while [ ! -f ${APP_LOG} ]
do
  sleep 1
  echo -n "."
done
echo -e "\nLog file found, continuing..."

tail -f $APP_LOG | while read LOGLINE
do
   [[ "${LOGLINE}" == *"Binding bundle: [landing-page"* ]] && pkill -P $$ tail
done

if [ -n "$INSTALL_FEATURES" ]; then
  if [[ $INSTALL_FEATURES == *";"* ]]; then
  _featureCount=$[$(echo $INSTALL_FEATURES | grep -o ";" | wc -l) + 1]
  else
    _featureCount=1
  fi

  echo "Preparing to install $_featureCount features"

  for (( i=1; i<=$_featureCount; i++ ))
  do
    _currentFeature=$(echo $INSTALL_FEATURES | cut -d ";" -f $i)
    echo "Installing: $_currentFeature"
    $APP_HOME/bin/client feature:install $_currentFeature
  done

  if [ -d "$ENTRYPOINT_HOME/post" ]; then
    for f in "$ENTRYPOINT_HOME/post/*";
      do
        chmod 755 $f
        echo "Running additional post_start configuration: $f"
        $f
      done;
  fi
fi

if [ -n "$UNINSTALL_FEATURES" ]; then
  if [[ $UNINSTALL_FEATURES == *";"* ]]; then
  _featureCount=$[$(echo $UNINSTALL_FEATURES | grep -o ";" | wc -l) + 1]
  else
    _featureCount=1
  fi

  echo "Preparing to uninstall $_featureCount features"

  for (( i=1; i<=$_featureCount; i++ ))
  do
    _currentFeature=$(echo $UNINSTALL_FEATURES | cut -d ";" -f $i)
    echo "Installing: $_currentFeature"
    $APP_HOME/bin/client feature:uninstall $_currentFeature
  done
fi

if [ -d "$ENTRYPOINT_HOME/post" ]; then
  for f in "$ENTRYPOINT_HOME/post/*";
    do
      chmod 755 $f
      echo "Running additional post_start configuration: $f"
      $f
    done;
fi

echo "To run additional post_start configurations mount a script to ${ENTRYPOINT_HOME}/post_start_custom.sh"

if [ -e "${ENTRYPOINT_HOME}/post_start_custom.sh" ]; then
  echo "Post-Start Custom Configuration Script found, running now..."
  chmod 755 ${ENTRYPOINT_HOME}/post_start_custom.sh && ${ENTRYPOINT_HOME}/post_start_custom.sh
fi
