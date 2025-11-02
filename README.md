[![tests](https://github.com/Metadrop/ddev-aljibe/actions/workflows/tests.yml/badge.svg)](https://github.com/Metadrop/ddev-aljibe/actions/workflows/tests.yml) ![project is maintained](https://img.shields.io/maintenance/yes/2025.svg)
![GitHub Release](https://img.shields.io/github/v/release/Metadrop/ddev-aljibe)

![Aljibe logo](https://metadrop.net/sites/default/files/2025-09/aljibe-image.png)

# DDEV Aljibe

## About Aljibe
Aljibe is a DDEV add-on for Drupal projects that adds several tools quickly and easily, leaving a new project ready for development in a few minutes.

Aljibe extends DDEV by adding containers, configuration, and commands to make the development of Drupal projects faster and easier.

## What does Aljibe provide?

- A folder tree tailored to Drupal good practices
- Static code analysis run manually and on each Git commit ([PHPStan](https://phpstan.org/), [PHP_CodeSniffer](https://github.com/PHPCSStandards/PHP_CodeSniffer/wiki), [PHPMD](https://phpmd.org/) and multiple linters)
- PHPUnit already configured
- [Behat](https://docs.behat.org/en/latest/) testing (BDD and Acceptance testing) ready to use
- Visual regression testing with [BackstopJS](https://github.com/Metadrop/ddev-backstopjs)
- Accessibility testing with [Pa11y](https://github.com/Metadrop/ddev-pa11y)
- API and HTTP testing with Newman and Postman collections
- Website quality audits with [Unlighthouse](https://github.com/Metadrop/ddev-unlighthouse)
- Smoke test for production environments using the provided testing tools
- Database management with Adminer
- Documentation wiki with [MkDocs](https://github.com/Metadrop/ddev-mkdocs)
- Frontend asset processing commands for custom themes
- Fast on-boarding and site management commands
- Multisite support
- Useful Drush configurations like Drush Policy to avoid accidental destructive commands on production
- Utility commands to create secondary databases or sync Solr configuration
- [Drupal Updater](https://github.com/Metadrop/drupal-updater) to update Drupal core and contributed modules automatically
- [Utility to create artefacts](https://github.com/Metadrop/drupal-artifact-builder) for deployments

See [Aljibe: quality and testing for Drupal development with DDEV](https://metadrop.net/en/articles/aljibe-quality-and-testing-drupal-developments-ddev) for a detailed introduction to Aljibe.


> **Note:** This tool is based on DDEV, so any DDEV add-on can work with Aljibe. Discover available add-ons with `ddev add-on list` for official DDEV add-ons or `ddev add-on list --all` for all available add-ons.

### Requirements

- [DDEV](https://ddev.readthedocs.io/en/stable/) v1.24.0 or higher
- [Docker](https://www.docker.com/) 24 or higher


## Quick start

New to Aljibe? Follow these steps to get started

1. **Create your project folder**

    `mkdir my-new-project && cd my-new-project`

2. **Initialise DDEV in this folder**

    `ddev config --auto`

3. **Install Aljibe**

    `ddev add-on get metadrop/ddev-aljibe`

4. **Run the assistant**

    `ddev aljibe-assistant`

The assistant will guide you through the installation and configuration of the tools provided by Aljibe, as well as the Drupal site installation. Once complete, your project will be ready for development with all Aljibe tools provided working out of the box.

For detailed instructions, see [Installation](#installation) below.


## Aljibe details

### A folder tree tailored for Drupal

Aljibe deploys folder structure and configuration files that follow Drupal best practices.

Folders:

- `config`: contains exported Drupal site configuration.
- `drush`: contains Drush commands, configuration and site aliases.
- `patches`: contains patches applied to Composer dependencies. It is [recommended to download patches and commit them locally](https://www.drupal.org/docs/develop/using-composer/manage-dependencies#patches). This folder is intended for storing those downloaded patches.
- `private-files`: contains private files for Drupal sites. Private files should not be stored in the web root for security reasons, so this folder is outside the web root.
- `recipes`: contains [recipes](https://www.drupal.org/docs/extending-drupal/drupal-recipes) for this project. Although recipes can be distributed as standard PHP packages, you can store project-specific recipes here that are not intended to be shared.
- `scripts`: custom scripts for your project can be stored here.



### Static code analysis and linters

Aljibe provides several static code analysis tools and linters to help maintain high code quality.

Because many tools are available, Aljibe uses two wrappers to manage them: GrumPHP and PHPQA.

GrumPHP runs automatically on each Git commit, while PHPQA is intended to be run manually or by your CI/CD system. Because both use the same underlying tools, they are configured similarly to ensure consistent results. Be sure to modify both configurations if you want to change the behaviour of any tool.

#### GrumPHP

GrumPHP runs code quality checks automatically on each Git commit. Aljibe configures GrumPHP with several tools and checks by default, including Git message check, Git branch name, file sizes, PHPStan, PHP_CodeSniffer with Drupal standards, PHPMD, and various linters.

To customise it, refer to your project's `.grumphp.yml` file. This file is provided by Aljibe during installation, but you can modify it to suit your project's needs.


#### PHPQA

PHPQA is a wrapper that allows you to run multiple PHP static analysis tools with a single command. Aljibe configures PHPQA to run the following tools by default: PHP_CodeSniffer with Drupal standards, PHPMD and PHP Parallel Lint.

PHPQA is intended to be run manually or by your CI/CD system.

To customise it, refer to your project's `.phpqa.xml` file. This file is provided by Aljibe during installation, but you can modify it to suit your project's needs.


### Behat testing (BDD/acceptance testing)

Behat is a Behaviour-Driven Development (BDD) framework for PHP. Aljibe includes Behat testing capabilities out of the box, allowing you to write and run acceptance tests for your Drupal site.

Behat is integrated with Drupal thanks to [Drupal Extension](https://www.drupal.org/project/drupalextension).

Aljibe includes two Behat test environments: `local` and `pro` (production). You can add more environments by creating additional folders inside `tests/behat/`.

   - `local`: for local and CI/CD tests. This environment uses the DDEV local instance.
   - `pro`: for production environment testing (usually smoke tests). This environment is intended to run tests against the live production site. Behat tests in this environment should be non-destructive and safe to run against a live site.  They should be short and not intensive, focusing on critical functionality to ensure the site is operational.

The `tests/common` folder contains shared features that are run on all environments.

All provided Behat features (test scenarios) should pass after Aljibe is installed. Look for files with the `.example` extension inside `tests/behat/` folders. These features usually require some Drupal modules or configuration and are not included by default to avoid having tests failing out of the box. If you want them, remove the `.example` extension and adapt them to your project.

#### Running Behat

Use the provided DDEV command to run tests from the default environment (`local `) with default options:

```bash
ddev behat
```

You can specify a different environment by providing the folder name in the `tests/behat/` directory. For example, to run the smoke tests in the `pro` environment:

```bash
ddev behat pro
```

If you want to provide additional options to Behat you need to add them after the environment name, which is mandatory. For example, to run tests with a specific tag:


```bash
ddev behat local --tags=@mytag
```


See [Behat Command Line Tool](https://docs.behat.org/en/latest/user_guide/command_line_tool.html) for more information.


Note that the `behat` command already includes the path to the configuration file


#### Behat contexts

Behat contexts are PHP classes that define the steps used in Behat features. Aljibe provides several additional contexts out of the box to facilitate testing common Drupal functionalities. Please check [nuvoleweb/drupal-behat](https://github.com/nuvoleweb/drupal-behat) and [metadrop/behat-contexts](https://github.com/Metadrop/behat-contexts) for more information about the provided contexts and how to use them.


###  Visual regression testing with BackstopJS

[BackstopJS](https://garris.github.io/BackstopJS/) is a tool for visual regression testing. Aljibe includes BackstopJS integration to help you catch visual changes in your Drupal site.

Aljibe provides two BackstopJS environments by default: `local` and `pro` (production). You can add more environments by creating additional folders inside `tests/backstopjs/`.

   - `local`: for local and CI/CD tests. This environment is the one provided by DDEV.
   - `pro`: for production environment testing (usually smoke tests). This environment is intended to run tests against the live production site. BackstopJS tests in this environment should fast and not intensive, focusing on critical pages to ensure the site is visually correct.

Each environment has its own `backstop.json` configuration file where the scenarios and settings are defined. For example, the URLs to test are defined here.

#### Using BackstopJS

BackstopJS requires reference screenshots to compare the current state of the site against. These reference screenshots should be created when the site is in a known good state.

To create the reference screenshots use the `reference` command.

```bash
ddev backstopjs [environment] reference
```

Later, to test the site against the reference screenshots, use the `test` command.

```bash
ddev backstopjs [environment] test
```


Check BackstopJS documentation for more information about available commands and options.

This feature is provided by a separate [DDEV add-on](https://addons.ddev.com/addons/Metadrop/ddev-backstopjs) that is automatically installed when you install run Aljibe assistant and select this feature.

### Accessibility testing with Pa11y

[Pa11y](https://pa11y.org/) is an automated accessibility testing tool. Aljibe includes Pa11y integration to help you ensure your Drupal site meets accessibility standards.

To get a report of accessibility issues on your site, run the following command:

```bash
ddev pa11y [site_url]
```

Pa11y configuration file can be found at `tests/pa11y/config.json`.

This feature is provided by a separate [DDEV add-on](https://addons.ddev.com/addons/Metadrop/ddev-pa11y) that is automatically installed when you install run Aljibe assistant and select this feature.

### API and HTTP testing with Newman and Postman collections

Testing API and HTTP responses can be done using Newman, the command-line companion for Postman. Aljibe optionally includes Newman integration to facilitate API testing.


You can test HTTP response codes on URLs or endpoints, check HTTP headers and validate JSON responses against schemas using Postman collections.

To run a Postman collection with Newman, use the following command:

```bash
ddev newman run <collection file> -e <environment file>
```

Example provided by Aljibe after installation:

```bash
ddev newman run postman/collections/example_cache_headers.postman_collection.json -e postman/envs/example_ddev.postman_environment.json
```


This feature is provided by a separate [DDEV add-on](https://addons.ddev.com/addons/Metadrop/ddev-newman) that is automatically installed when you install run Aljibe assistant and select this feature.



### Website quality audits with Unlighthouse

Unlighthouse is a tool for auditing website quality, performance, SEO, and accessibility. It uses Lighthouse under the hood to perform these audits.

Aljibe includes Unlighthouse integration to help you maintain high-quality websites.

Unlighthouse can autodiscover site URLs and follow a sitemap.

To run it against your local site, use the following command:

```bash
ddev unlighthouse
```

This command uses the Unlighthouse configuration file located at `tests/unlighthouse/local/unlighthouse.ts`.

You can add more environments by creating additional folders inside `tests/unlighthouse/`.


This feature is provided by a separate [DDEV add-on](https://addons.ddev.com/addons/Metadrop/ddev-unlighthouse) that is automatically installed when you install run Aljibe assistant and select this feature.

### Smoke tests

Smoke tests are a set of basic tests that verify the critical functionality of a website.

Aljibe allows you to run smoke tests against production environments using the provided testing tools: Behat, BackstopJS, Pa11y, Newman and Unlighthouse.

### Database management with Adminer

Aljibe provides a ready-to-use Adminer installation for database management.

This feature is provided by a separate [DDEV add-on](https://addons.ddev.com/addons/ddev/ddev-adminer) that is automatically installed when you install run Aljibe assistant and select this feature.

### Documentation wiki with MkDocs

[MkDocs](https://www.mkdocs.org/) is a static site generator that's geared towards project documentation. Aljibe provides an MkDocs installation with [MkDocs Material](https://squidfunk.github.io/mkdocs-material/), a popular theme for MkDocs that provides additional functionality and a modern look.

You can find the main configuration file at `docs/mkdocs.yml` and the documentation content inside the `docs/docs/` folder.

Aljibe already provides a boilerplate documentation structure that you can modify to suit your project's needs.

Check MkDocs and MkDocs Material documentation for more information on how to create and manage your documentation.

This feature is provided by a separate [DDEV add-on](https://addons.ddev.com/addons/Metadrop/ddev-mkdocs) that is automatically installed when you install run Aljibe assistant and select this feature.


### Frontend asset processing for custom themes

Many Drupal themes require a compilation process relying on Node.js, like [Radix](https://www.drupal.org/project/radix) or [Artisan](https://www.drupal.org/project/artisan) themes. Aljibe provides commands to facilitate the processing of theme assets.

To generate production assets for a theme, run:

```bash
ddev frontend production [theme_name]
```

Where `theme_name` is the key defined in `.ddev/aljibe.yml`. If omitted, the command processes all defined themes.

After installation, there is one example theme defined in `.ddev/aljibe.yml` with the name "custom_theme". You can [add multiple themes](#advanced-configuration).

### Fast on-boarding and site management commands

Aljibe aims to ease site management tasks with several provided commands.


#### Site installation

First, Aljibe makes it easy to install a site from a known base to start development. The command `site-install` installs a site using either a configuration export or a database dump.

During development, it is common to configure the local site with a known setup for testing and development. Many times this is done using a database dump from a staging or production server.

Another option is to use a configuration export to set up the site, and use default content to populate the site with content to be able to test functionalities. This is the recommended way when working with Drupal projects that have a complete configuration management workflow, because it allows predictable setup times, avoid any privacy issues with real data (no need for sanitisation) and is usually faster than importing a database dump.


##### Installing from configuration

To install the default site from the configuration export, run:

```bash
ddev site-install
```

For this to work, a Drupal configuration export must be available. The command uses Drush commands (`sql-drop`, `site:install` and `config-import`) to perform the installation from existing configuration.

To install a different site other than the default, use its site name:

```bash
ddev site-install <site_name>
```

Where `site_name` is the site alias defined in your Drush aliases, or just the name without dots (in this case, `.local` will be appended automatically) for local sites:

```bash
ddev site-install site1   # Installs @site1.local
ddev site-install site2.mylocal  # Installs @site2.mylocal
```

##### Installing from database dump

Run the following command to install a site from a database dump:

```bash
ddev site-install site1 path/to/dump.sql   # Installs @site1.local using the provided database dump
```

In this case, the site name is mandatory, as well as the path to the database dump file.


##### Fast on-boarding

The `setup` commands allow for fast on-boarding of new developers by automating the site installation process. A new developer only needs to clone the project repository and run `ddev setup` to have a working local site ready for development.

The `setup` command installs Composer dependencies and installs the site (or sites in a multisite setup) using `site-install`.

This command currently supports only installation from configuration exports.



#### Hooking into the setup and site installation process

Both commands, `setup` and `site-install`, provide hooks to allow you to run custom commands at different stages of the process. This is useful for performing additional setup tasks if your project requires special steps.

Check [hooks](#hooks) configuration property of `.ddev/aljibe.yml` file for more information about available hooks and how to use them.


### Multisite support

Aljibe supports multisite setups using Drush aliases. Some commands allow you to select the site using Drush aliases, while others require you to provide the appropriate configuration.

For example, use different Behat profiles for different sites, or provide absolute URLs to BackstopJS or Pa11y commands, or use the site name in the `site-install` command.


### Utility commands

Some commands are provided to ease certain operations:

  - `ddev all-sites-drush`: run a Drush command on all sites in the multisite installation.
  - `ddev create-database`: create secondary databases. This is useful if your site requires another database, or when you are adding a new site to your project and you need to create its database.

### Drupal Updater

[Drupal Updater](https://github.com/Metadrop/drupal-updater) is a tool to update Drupal core and contributed modules automatically. Aljibe includes Drupal Updater integration to help you keep your Drupal installation up to date.

This PHP package is able to update each module or theme in separate commits, update Drupal configuration and even update the Drupal core itself. It relies on Composer to perform the updates.

Read more about Drupal Updater in this article: [Drupal Updater: Streamlining Drupal Maintenance Updates from CLI](https://metadrop.net/en/articles/drupal-updater-streamlining-drupal-maintenance-updates-cli).

Use the following command to run it:

```bash
ddev exec vendor/bin/drupal-updater
```

### Artefact Builder

When deploying a Drupal site, it is often recommended to create artefacts that can be deployed to the production server. These artefacts include only the necessary files for the site to run, excluding development dependencies and unnecessary files.

Aljibe includes [Drupal Artefact Builder](https://github.com/Metadrop/drupal-artifact-builder), a tool to create Drupal artefacts for deployments from the current state of the codebase.


Use the following command to run it:

```bash
ddev exec vendor/bin/drupal-artifact-builder
```

### Add Aljibe to existing projects

To transform an existing project to use DDEV Aljibe, follow these steps. Always take into account the particularities of your specific project:

#### Basic migration steps

1. **Prepare the project:**
   - Clone the project without installing dependencies
   - Remove all Docker-related files from the project root

2. **Configure basic DDEV:**
   ```sh
   ddev config --auto
   ```

3. **Install Aljibe:**
   ```sh
   ddev get metadrop/ddev-aljibe
   ```

4. **Fine-tune DDEV configuration** using the interactive assistant:
   ```sh
   ddev config
   ```
   Set the project type to Drupal, specify the docroot folder, etc.

5. **Configure Aljibe:**
   - Edit `.ddev/config.yml` to fine-tune the environment
   - Edit `.ddev/aljibe.yml` to set the default site name (the folder inside `sites/`) and all themes to be compiled
   - Update `.gitignore` to match [this example](https://github.com/Metadrop/ddev-aljibe/blob/main/kickstart/common/.gitignore)

#### Additional steps for boilerplate projects

If you're migrating from a [Metadrop boilerplate](https://github.com/Metadrop/drupal-boilerplate) project:

1. **Clean up settings.local.php:**
   - Remove database configuration (handled by `settings.ddev.php`)
   - Remove trusted host patterns that may conflict with DDEV settings

2. **Update drush aliases:**
   - Adapt the drush alias to the new local URL

3. **Update test configuration:**
   - Review `tests/` folder structure (in Aljibe, all tests including `behat.yml` are inside the `tests/` folder)
   - Replace `http://apache` or `http://nginx` with `http://web` in all test configurations

4. **Configure Node.js version:**
   - Set `nodejs_version` in `.ddev/config.yml` to match your previous project
   - The old version can be found in the `.env` file under the **"NODE_TAG"** variable

5. **Adapt GrumPHP:**
   - Change `EXEC_GRUMPHP_COMMAND` in `grumphp.yml` to `"ddev exec"`

6. **Launch setup:**
   - Single site: `ddev setup`
   - Multisite (all sites): `ddev setup --all`
   - Multisite (specific site): `ddev setup --sites=site1`

## Advanced configuration

The `aljibe.yml` file allows you to customise various aspects of the Aljibe setup. This file is located at `.ddev/aljibe.yml` and is created automatically when you install Aljibe.

### Configuration options

#### `default_site`

Sets the default site name to be installed by the setup command when no specific site name is provided.

**Example:**
```yaml
default_site: my_site
```

With this configuration:
- `ddev setup` will install the site "my_site"
- This is equivalent to running `ddev setup my_site`

> **Note:** Site names must match drush aliases. Names without dots are automatically considered as ".local" aliases. If you have a different alias suffix, you can specify it explicitly and ".local" will not be appended.


#### `theme_paths`

Defines paths to custom themes that work with the `ddev frontend` command. Each theme should be listed with a unique key that you'll use when running frontend commands.

**Example:**
```yaml
theme_paths:
  custom_theme: /var/www/html/web/themes/custom/custom_theme
  admin_theme: /var/www/html/web/themes/custom/admin_theme
```

**Usage:**
```sh
ddev frontend production custom_theme  # Build production assets for custom_theme
ddev frontend watch admin_theme        # Watch mode for admin_theme
```

#### `hooks`

Hooks are commands that execute at different stages of the setup process. They are defined as lists of commands under various hook points, allowing you to customise the workflow to your project's needs.

**Available hooks:**

**Setup hooks:**
- `pre_setup`: Commands to run before the setup process
- `post_setup`: Commands to run after the setup process

**Site installation hooks:**
- `pre_site_install`: Commands to run before any type of site installation
- `post_site_install`: Commands to run after any type of site installation
- `pre_site_install_config`: Commands to run before site installation from configuration
- `post_site_install_config`: Commands to run after site installation from configuration
- `pre_site_install_db`: Commands to run before site installation from database dump
- `post_site_install_db`: Commands to run after site installation from database dump

**Example configuration:**

```yaml
hooks:
  pre_setup:
    - echo "Aljibe pre setup hook"
    - ddev snapshot
  post_setup:
    - echo "Aljibe post setup hook"
    - ddev drush uli --uid=2
  pre_site_install: []
  post_site_install:
    - ddev @${SITE_ALIAS} drush cr
  pre_site_install_config: []
  post_site_install_config: []
  pre_site_install_db: []
  post_site_install_db: []
```

**Available variables in hooks:**

Site installation hooks (`pre_site_install`, `post_site_install`, etc.):
- `DRUPAL_PROFILE`: The profile used to install the site
- `SITE_PATH`: The path to the site relative to `web/sites`
- `SITE_ALIAS`: The drush alias of the site (without the `@` prefix)

Setup hooks (`pre_setup`, `post_setup`):
- `NO_THEMES`: Set if `--no-themes` flag was used
- `NO_INSTALL`: Set if `--no-install` flag was used
- `SITES`: The sites to be installed
- `CONFIG_DEFAULT_SITE`: The default site configured

All [DDEV environment variables](https://ddev.readthedocs.io/en/stable/users/extend/custom-commands/#command-line-completion) are also available in all hooks.

#### `installable_sites_aliases`

Defines the list of sites to install when running `ddev setup --all`. Additional sites can still be installed later using the `ddev site-install <site_name>` command.

**Example:**
```yaml
installable_sites_aliases:
  - site1
  - site2
  - site3.mylocal
```

> **Note:** Site names must match drush aliases. Names without dots are automatically considered as ".local" aliases. If you have a different alias suffix, you can specify it explicitly and ".local" will not be appended.

### Reading configuration programmatically

You can add any custom configuration you need to the `aljibe.yml` file. This configuration can be retrieved programmatically with the `ddev aljibe-config` command, which is useful for scripting and automation.

**Example commands:**

Get all theme paths:
```sh
ddev aljibe-config theme_paths
```

Get the default site:
```sh
ddev aljibe-config default_site
```

Get any custom configuration key:
```sh
ddev aljibe-config my_custom_key
```

## Troubleshooting

Common issues and their solutions.

### HTTPS not working

HTTPS requires proper SSL certificate configuration on your system.

**Solution:**

1. Follow DDEV [installation recommendations](https://ddev.readthedocs.io/en/stable/users/install/ddev-installation/#linux)
2. Install required packages: `mkcert` and `libnss3-tools`
3. Run the certificate installation:
   ```sh
   mkcert -install
   ```

### Debugging with NetBeans

Due to [NetBeans issue #7562](https://github.com/apache/netbeans/issues/7562), you need to manually configure Xdebug for NetBeans.

**Solution:**

Create a file named `xdebug.ini` in `.ddev/php/` with the following content:

```ini
[XDebug]
xdebug.idekey = netbeans-xdebug
```

**Note:** `netbeans-xdebug` is the default Session ID value in the Debugging tab of NetBeans' PHP configuration dialogue. If you've changed it, update the `xdebug.ini` file accordingly.

### Xdebug Profiler not saving files

If Xdebug profiling files aren't being generated, you need to configure the profiler output directory.

**Solution:**

Follow the [DDEV Xdebug profiling documentation](https://ddev.readthedocs.io/en/stable/users/debugging-profiling/xdebug-profiling/#basic-usage) and create a file named `xdebug.ini` in `.ddev/php/` with:

```ini
[XDebug]
xdebug.mode=profile
xdebug.start_with_request=yes
# Set a DDEV shared folder for the xprofile reports
xdebug.output_dir=/var/www/html/tmp/xprofile
xdebug.profiler_output_name=trace.%c%p%r%u.out
```

**Verification:**

1. Run `ddev xdebug on`
2. Restart the project if necessary
3. Visit `/admin/reports/status/php` (Drupal) to verify Xdebug variables are configured correctly
