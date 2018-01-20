If (Test-Path $env:APP_HOSTNAME) {
  $env:_app_hostname=$env:APP_HOSTNAME
}
Else {
  $shortName=(Get-WmiObject win32_computersystem).DNSHostName
  $domainName=(Get-WmiObject win32_computersystem).Domain
  If (Test-Path $domainName) {
    $env:_app_hostname=$shortName+"."+$domainName
  }
  Else {
    $env:_app_hostname=$shortName
  }
}

Write-Output "External Hostname: $env:_app_hostname"
Write-Output "Updating $env:APP_NAME certificates"

Write-Output "APP_HOME: $env:APP_HOME"

$env:APP_HOME\etc\certs\CertNew.bat -cn $env:_app_hostname

Get-Content $env:APP_HOME\etc\system.properties | % { $_ -replace "localhost","$env:_app_hostname" }

Get-Content $env:APP_HOME\etc\users.properties | % { $_ -replace "localhost","$env:_app_hostname" }

Get-Content $env:APP_HOME\etc\users.attributes | % { $_ -replace "localhost","$_app_hostname" }

Get-Content env:windir\System32\drivers\etc\hosts | % { $_ -replace "localhost","localhost $env:_app_hostname" }

Get-ChildItem "$env:ENTRYPOINT_HOME\pre" -Filter *.ps |
Foreach-Object {
  Write-Output "Running additional pre_start configuration: $_"
  Invoke-Expression $_
}

Write-Output "To run additional pre_start configurations mount a script to $env:ENTRYPOINT_HOME\pre_start_custom.ps"

Test-Path ($env:ENTRYPOINT_HOME\pre_start_custom.ps) {
  Write-Output "Pre-Start Custom Configuration Script found, running now..."
  Invoke-Expression $env:ENTRYPOINT_HOME\pre_start_custom.ps
}
