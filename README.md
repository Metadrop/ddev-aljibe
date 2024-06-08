# DDEV Aljibe

DDEV Aljibe (ddev-aljibe) is an addon for DDEV that enables the installation of a Drupal project based on Aljibe in a simple and fast way, leaving a new project ready for development in a few minutes.

## Requirements
- [DDEV](https://ddev.readthedocs.io/en/stable/) 1.22 or higher
- [Docker](https://www.docker.com/) 24 or higher

## Installation
- See the following [Wiki](https://gitlab.metadrop.net/metadrop-group/ddev-aljibe/-/wikis/Instalaci%C3%B3n-local-y-ejecuci%C3%B3n-de-Aljibe)

**NOTE**: Please note that Aljibe is not yet published, once published everything will be automatically downloaded from github.

## Troubleshooting

### Https not working

It is needed to install mkcert and libnss3-tools, and then run:

```
mkcert -install
```

[More information](https://ddev.com/blog/ddev-local-trusted-https-certificates/)