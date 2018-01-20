# escape=` (backtick)
FROM oconnormi/windows-java:jdk
MAINTAINER oconnormi

ENV ENTRYPOINT_HOME=C:\entrypoint

RUN powershell -Command `
    $ErrorActionPreference = 'Stop' ; `
    $progressPreference = 'silentlyContinue' ; `
    New-Item $ENTRYPOINT_HOME

COPY entrypoint\*.ps $ENTRYPOINT_HOME\

ENTRYPOINT ["powershell", "-Command", "$ENTRYPOINT_HOME/entrypoint.ps"]
