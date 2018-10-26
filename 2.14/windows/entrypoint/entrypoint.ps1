If (Test-Path $env:ENTRYPOINT_HOME\pre_start.ps) {
  Write-Output "Pre-Start Configuration Script found, running now..."
  Invoke-Expression $env:ENTRYPOINT_HOME\pre_start.ps
}

Write-Output "Starting $env:APP_NAME"

Invoke-Expression $env:APP_HOME/bin/start

Start-Sleep -s 2

If (Test-Path $env:ENTRYPOINT_HOME\post_start.ps) {
  Write-Output "Post-Start Configuration Script found, running now..."
  Invoke-Expression $env:ENTRYPOINT_HOME\post_start.ps
}

Get-Content -File $env:APP_LOG -Wait
