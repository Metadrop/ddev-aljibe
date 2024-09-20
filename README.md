[![tests](https://github.com/Metadrop/ddev-aljibe/actions/workflows/tests.yml/badge.svg)](https://github.com/Metadrop/ddev-aljibe/actions/workflows/tests.yml) ![project is maintained](https://img.shields.io/maintenance/yes/2024.svg)
![GitHub Release](https://img.shields.io/github/v/release/Metadrop/ddev-aljibe)


# DDEV Aljibe

Aljibe (ddev-aljibe) is an add-on for DDEV for Drupal projects that adds several tools in a simple and fast way, leaving a new project ready for development in a few minutes.

Aljibe sits on top of DDEV and adds some containers, configuration and commands to make the development of Drupal projects faster and easier.

## Included tools

  - Behat: BDD and Acceptance testig
  - BackstopJS: Visual regression testing
  - Lighthouse: Audit website quality
  - Pa11y: Accesibility checks
  - MkDocs: Documentation wiki
  - And more...
    

## Requirements
- [DDEV](https://ddev.readthedocs.io/en/stable/) 1.23.1 or higher
- [Docker](https://www.docker.com/) 24 or higher

## Creating a new project

Create a folder for your new project (e.g. `mkdir my-new-project`)
Configure a basic ddev project:

    ddev config --auto
   

Install the Aljibe addon. This will install all the dependant addons too:

    ddev get metadrop/ddev-aljibe

Launch Aljibe Assistant. This will guide you throught the basic Drupal site instalation process:

    ddev aljibe-assistant

You are ready! you will have a new Drupal project based on Aljibe ready for development.

## Migrate legacy projects to DDEV Aljibe

To transform a legacy project to Ddev Aljibe, the following steps must be followed, always taking into account the particularities of each project:

1. Clone the project without install it and remove all docker related files 
2. Run basic ddev-config:
	- `ddev config --auto`
3. Install Aljibe:
	- `ddev get metadrop/ddev-aljibe`
4. Run again ddev config, but this time go throught the assistant to set project type to Drupal, docroot folder, etc...
5. Edit .ddev/config.yml to fine tune the environment.
6. Edit .ddev/aljibe.yml to set deault site name (the folder inside sites) and all themes to be transpiled
7. update .gitignore to look like [this](https://github.com/Metadrop/ddev-aljibe/blob/main/aljibe-kickstart/.gitignore).

If you come from a boilerplate project:

- Remove from settings.local.php database, trusted host patterns and others that can conflict with settings.ddev.php.
- Adapt the drush alias to the new url.
- Review tests folder structure as in aljibe, all tests (behat.yml included) are inside tests folder and replace http://apache or http://nginx by http://web.
- Config also the nodejs_version in .ddev/config.yml with the same as the old project. Old version on .env file, variable **“NODE_TAG”**
- Adapt grumphp changing EXEC_GRUMPHP_COMMAND on grumphp.yml to “ddev exec”
- Launch ddev setup:
    - If monosite: `ddev setup`
    - If multisite:`ddev setup —all` or `ddev setup --sites=site1`
    
## Aljibe commands

#### Project setup 
Once the project has been created and uploaded to version control, anyone else working with it can clone it and with the following command you can have the project ready to work with.

    ddev setup [--all] [--no-install] [--no-themes]

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

#### Power off ddev
    
    ddev poweroff

## Troubleshooting

### Https not working

It is needed to install mkcert and libnss3-tools, and then run:


mkcert -install


[More information](https://ddev.com/blog/ddev-local-trusted-https-certificates/)

### Can't debug with NetBeans
Until https://github.com/apache/netbeans/issues/7562 is solved you need to create a file named `xdebug.ini` at `.ddev/php` with the following content:
```
[XDebug]
xdebug.idekey = netbeans-xdebug
```
NOTE: The `netbeans-xdebug` is the default Session ID value in the the Debugging tab in the PHP Netbeans' configuration dialog. If you have changed it do it in the `xdebug.ini` file as well.

### Xdebug profiler does not save the files

Follow the instructions from [ddev xprofiler documentation](https://ddev.readthedocs.io/en/stable/users/debugging-profiling/xdebug-profiling/#basic-usage)

```
[XDebug]
xdebug.mode=profile
xdebug.start_with_request=yes
# Set a ddev shared folder for the xprofile reports.
xdebug.output_dir=/var/www/html/tmp/xprofile
xdebug.profiler_output_name=trace.%c%p%r%u.out

```

Review the php info (/admin/reports/status/php) page to review that the xdebug variables are setup properly after run ddev xdebug on, restart the project if necessary.

## How to develop Aljibe

To work on the development of Aljibe, if we do a lot of tests we can reach the limit of github, so it is convenient to have everything in local. For this we should have a structure like this:

- tests-aljibe <- Here we test the creation of projects with the steps explained below. This folder can have any name you want.
- ddev-addons <- Here are all the addons from Metadrop:
    - ddev-aljibe
    - ddev-aljibe-assistant
    - ddev-backstopjs
    - ddev-lighthouse
    - ddev-mkdocs
    - ddev-pa11y
    - ddev-selenium

To have this folder, we can do the following from the folder where we save the projects:

1. Create the folder and got to that folder:
```
mkdir ddev-addons && cd ddev-addons
```

2. Clone the projects:
```
 
git clone git@gitlab.metadrop.net:metadrop-group/ddev-aljibe.git
git clone git@gitlab.metadrop.net:metadrop-group/ddev-aljibe-assistant.git
git clone git@github.com:Metadrop/ddev-backstopjs.git
git clone git@github.com:Metadrop/ddev-lighthouse.git
git clone git@github.com:Metadrop/ddev-mkdocs.git
git clone git@github.com:Metadrop/ddev-pa11y.git
git clone git@github.com:Metadrop/ddev-selenium.git   
    
```
#### Installing Aljibe:

To launch ddev-aljibe, we must go to the test-aljibe folder, or to the folder where we want to install it. Remember that as long as we don't have Aljibe public, this folder must be at the same level as the ‘ddev-addons’ folder. Inside this folder, just launch these 3 commands:

1.  Configure a basic ddev project:
```
ddev config --auto 
```
2. Install ddev-aljibe from local:
```
ddev get ../ddev-addons/ddev-aljibe
```
3. Launch the Aljibe assistant:
```
ddev aljibe-assistant
```
