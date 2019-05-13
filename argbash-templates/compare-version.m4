#!/bin/bash

# m4_ignore(
echo "This is just a script template, not the script (yet) - pass it to 'argbash' to fix this." >&2
exit 11  #)Created by argbash-init v2.7.1
# ARG_OPTIONAL_BOOLEAN([greater-than], [g], [Checks if version is greater than the target version])
# ARG_OPTIONAL_BOOLEAN([less-than], [l], [Checks if version is less than the target version])
# ARG_POSITIONAL_SINGLE([version], [version to compare])
# ARG_POSITIONAL_SINGLE([target-version], [version to compare against])
# ARG_DEFAULTS_POS
# ARG_HELP([Compares version against a target version. Exits 0 when condition is met, exits 1 otherwise])
# ARGBASH_GO

# [ <-- needed because of Argbash

declare -a _version
declare -a _targetVersion

function versionsToArray {
    IFS='.' read -r -a _version <<< "${_arg_version}"
    IFS='.' read -r -a _targetVersion <<< "${_arg_target_version}"
}

function validate {

  if [ "${#_version[@]}" -ne "${#_targetVersion[@]}" ]; then
    printf "\ninvalid\n"
    return 20
  fi

  return 0
}

function greaterThan {
   for index in "${!_version[@]}"
   do
     if [ ${_version[$index]} -lt ${_targetVersion[$index]} ]; then
        return 1
     fi
   done
   return 0
}

function lessThan {
  for index in "${!_version[@]}"
  do
     if [ ${_version[$index]} -gt ${_targetVersion[$index]} ]; then
        return 1
     fi
  done
  return 0
}
function main {
  versionsToArray
  if [ $? -ne 0 ]; then
    return $?
  fi
  validate
  if [ $? -ne 0 ]; then
    return $?
  fi

  if [ "${_arg_greater_than}" == "on" ]; then
    greaterThan
    return $?
  fi

  if [ "${_arg_less_than}" == "on" ]; then
    lessThan
    return $?
  fi

  return 2
}

main
exit $?

# ] <-- needed because of Argbash
