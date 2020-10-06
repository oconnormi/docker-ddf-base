#!/bin/bash

_catalog_framework_config=${_app_etc}/ddf.catalog.CatalogFrameworkImpl.config

echo "'CATALOG_FANOUT_MODE is set to true. Enabling Catalog Fanout Mode now!"

if [ ! -f "${_catalog_framework_config}" ]; then
  touch ${_catalog_framework_config}
fi

props set fanoutEnabled true ${_catalog_framework_config}
