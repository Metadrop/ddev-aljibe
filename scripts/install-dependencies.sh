#!/bin/sh
#ddev-generated


ddev add-on get ddev/ddev-adminer
ddev add-on get Metadrop/ddev-mkdocs
ddev add-on get Metadrop/ddev-backstopjs
ddev add-on get Metadrop/ddev-lighthouse
ddev add-on get Metadrop/ddev-selenium
ddev add-on get Metadrop/ddev-pa11y
ddev add-on get Metadrop/ddev-unlighthouse
ddev add-on get Metadrop/ddev-aljibe-assistant

## We should check if memcached is already installed to not install redis in case we are updating.
if ! ddev add-on get --installed | grep memcached -q; then
  echo "ddev-memcached no está instalado. Instalando ddev/ddev-redis..."
  ddev add-on get ddev/ddev-redis
fi


