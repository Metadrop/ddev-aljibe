# DDEV Aljibe

DDEV Aljibe (ddev-aljibe) is an addon for DDEV that enables the installation of a Drupal project based on Aljibe in a simple and fast way, leaving a new project ready for development in a few minutes.

## Requirements
- [DDEV](https://ddev.readthedocs.io/en/stable/) 1.22 or higher
- [Docker](https://www.docker.com/) 24 or higher

## Creating a new project

1. Create a folder for your new project (e.g. `mkdir my-new-project`)
2. Configure a basic ddev project:

    ddev config --auto

3. Install the Aljibe addon. This will install all the dependant addons too:

    ddev get metadrop/ddev-aljibe

4. Finally launch Aljibe Assistant. This will guide you throught the basic Drupal site instalation process:

    ddev aljibe-assistant

Once this process is finished, you will have a new Drupal project based on Aljibe ready for development.

## Other Aljibe commands

#### Project setup 
Once the project has been created and uploaded to version control, anyone else working with it can clone it and with the following command you can have the project ready to work with.

    ddev setup

#### Unique site install (Multisite)
If you have a multisite instalation, you can install only one site by running:

    ddev site-install <site_name>

#### Create a secondary database
If you need to create a secondary database, you can run:

    ddev create-database <db_name>

**NOTE**: This command will create a database accesible with the same user and password from the main one. If you want to persist this across multiples setups, you can add this command to te pre-setup hooks in .ddev/aljibe.yml file. 

#### Launch behat tests
To launch local, or env tests, you can run:

    ddev behat [local|pro|other_behat_folder] [suite]

#### Process custom themes CSS
By default there is one theme defined in .ddev/aljibe.yml. You can add multiple themes. To process them, run:

    ddev frontend production [theme_name]

where theme_name is the key defined in .ddev/aljibe.yml. You can run a watch command to process the CSS on the fly:

    ddev frontend watch [theme_name]

#### Sync solr config
If you use ddev-solr addon and need to sync the solr config from the server, you can run:

    ddev solr-sync

## Troubleshooting
   - WIP
### Https not working

It is needed to install mkcert and libnss3-tools, and then run:


mkcert -install


[More information](https://ddev.com/blog/ddev-local-trusted-https-certificates/)