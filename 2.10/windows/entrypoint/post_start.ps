#!/bin/bash

Get-ChildItem "$env:ENTRYPOINT_HOME\post" -Filter *.ps |
Foreach-Object {
  Write-Output "Running additional post_start configuration: $_"
  Invoke-Expression $_
}

Write-Output "To run additional post_start configurations mount a script to $env:ENTRYPOINT_HOME\post_start_custom.ps"

Test-Path ($env:ENTRYPOINT_HOME\pre_start_custom.ps) {
  Write-Output "Post-Start Custom Configuration Script found, running now..."
  Invoke-Expression $env:ENTRYPOINT_HOME\pre_start_custom.ps
}
