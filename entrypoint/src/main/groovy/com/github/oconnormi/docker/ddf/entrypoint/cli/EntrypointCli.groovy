package com.github.oconnormi.docker.ddf.entrypoint.cli

import com.github.oconnormi.docker.ddf.entrypoint.Entrypoint
import com.github.oconnormi.docker.ddf.entrypoint.config.AppMetadata
import com.github.oconnormi.docker.ddf.entrypoint.config.EntrypointConfig

def run(args) {
    AppMetadata appMetadata = new AppMetadata(System.getenv())

    def cli = new CliBuilder(usage: 'entrypoint [options]')
    cli.header = "Bootstraps DDF Based Systems"
    cli._(longOpt: 'solr-mode', args: 1, argName: 'solrMode',
            'Choose Solr client mode. Options are: [http (default), cloud]')
    cli.s(longOpt: 'solr-url', args: 1, argName: 'solrHost',
            'Specify the Solr client connection. If using Solr Cloud this will be a comma-separated list of zookeeper `host:port`'
    )
    cli.c(longOpt: 'cluster', args: 1, argName: 'clusterName', 'Enables clustered mode. Sets cluster name')
    cli.l(longOpt: 'ldap-host', args: 1, argName: 'ldapHost',
            'Configures ldap connection. Use hostname only (This is currently for testing only)')
    cli.i(longOpt: 'install-config', args: 1, 'Path to json config file for automated installs')
    cli.h(longOpt: 'help', 'print this message')

    def options = cli.parse(args)
    if (options.help) {
        cli.usage()
        System.exit(0)
    }

    def config = new EntrypointConfig(appMetadata, options)

    def entrypoint = new Entrypoint()
    int exit = entrypoint.run(config)
    System.exit(exit)
}

run(args)
