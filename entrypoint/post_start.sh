#!/bin/bash

echo "This is a placeholder script, replace this with a customized Post-Start configuration script as needed by volume mounting a file to ${ENTRYPOINT_HOME}/post_start.sh"

if [ -d "$ENTRYPOINT_HOME/post" ]; then
  for f in "$ENTRYPOINT_HOME/post/*.sh";
    do
      [ -d $f ] && chmod 755 $f \
      && echo "Running additional post_start configuration: $f" \
      && $f
    done;
fi
