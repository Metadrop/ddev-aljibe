#!/bin/sh
#ddev-generated

ddev get ddev/ddev-adminer
ddev get Metadrop/ddev-mkdocs
ddev get Metadrop/ddev-backstopjs
ddev get Metadrop/ddev-lighthouse
ddev get Metadrop/ddev-selenium
ddev get Metadrop/ddev-pa11y
ddev get Metadrop/ddev-unlighthouse
ddev get Metadrop/ddev-aljibe-assistant

## We should check if memcached is already installed to not install redis in case we are updating.
if ! ddev get --installed | grep memcached -q; then
  echo "ddev-memcached no está instalado. Instalando ddev/ddev-redis..."
  ddev get ddev/ddev-redis
fi


