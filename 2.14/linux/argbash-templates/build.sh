#!/bin/bash

_cmd_output=${CMD_OUTPUT:="/out/cmd"}
_completion_output=${COMPLETION_OUTPUT:="/out/completion"}

mkdir -p ${_cmd_output}
mkdir -p ${_completion_output}

for f in *.m4
do
  file="${f#.}"
  _cmd_file="${_cmd_output}/${file%.m4}"
  _completion_file="${_completion_output}/${file%.m4}.sh"

  echo "Creating command ${_cmd_file} from ${file}"
  argbash "${file}" -o "${_cmd_file}"
  echo "Creating completion ${_completion_file} from ${file}"
  argbash --type completion "${file}" -o "${_completion_file}"
done
