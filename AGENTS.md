# AGENTS.md

Guidance for AI coding agents working in this repository.

## About This Repository

This is **ddev-aljibe**, a DDEV add-on for Drupal projects that provides a complete development environment with integrated testing tools, frontend build systems, and standardized workflows. It sits on top of DDEV and extends it with additional containers, commands, and configuration specifically for Drupal development.

**Requirements:** DDEV v1.24.0+, Docker 24+

This is the **add-on development repository**, not a Drupal project.

## Repository Structure

- `commands/` - DDEV custom commands organized by execution context
- `kickstart/` - Starter templates for new Drupal projects
- `scripts/` - Installation and setup scripts
- `tests/` - BATS tests for the add-on (see [Testing This Add-on](#testing-this-add-on))
- `config.aljibe.yaml` - Additional DDEV configuration injected into projects

## Core Architecture

### Add-on Installation System

The add-on uses a dependency installation system (`scripts/aljibe-install-dependencies.sh`) that automatically installs and manages several DDEV add-ons:
- ddev-adminer (database management)
- ddev-mkdocs (documentation)
- ddev-backstopjs (visual regression testing)
- ddev-selenium (browser automation)
- ddev-pa11y (accessibility testing)
- ddev-unlighthouse (site quality audit)
- ddev-newman (API testing)
- ddev-redis (caching - installed only if memcached not present)
- ddev-aljibe-assistant (optional setup wizard)

### Kickstart System

The `kickstart/` directory contains starter templates organized by Drupal version:
- `kickstart/common/` - Shared configuration, settings, tests, and drush commands
- `kickstart/d10/` - Drupal 10 specific files
- `kickstart/d11/` - Drupal 11 specific files

These templates are used when setting up new projects via `ddev aljibe-assistant` or `ddev aljibe-kickstart`.

### Configuration Files

- **aljibe.yaml** (or aljibe.yml): Main configuration file for Aljibe-specific settings
  - `default_site`: Default site for setup commands
  - `theme_paths`: Theme definitions for frontend build commands
  - `installable_sites_aliases`: Sites to install with `--all` flag
  - `hooks`: Pre/post hooks for setup and site installation
- **site-profiles**: Bash script that sets `DRUPAL_PROFILE` variable based on site name for installations

### Command Structure

Commands are organized in subdirectories by execution context:
- `commands/web/`: Execute inside web container
  - `behat` - Runs Behat tests with config from tests/behat/$FOLDER/behat.yml
  - `frontend` - Executes npm scripts in theme directories defined in aljibe.yaml
- `commands/host/`: Execute on host
  - `setup` - Main orchestration command for environment setup and site installation
  - `site-install` - Installs individual sites from config or database dumps (optionally with a files archive)
  - `site-install-from-db` - Deprecated wrapper around `site-install`
  - `aljibe-config` - Reads configuration from aljibe.yaml using yq
  - `aljibe-kickstart` - Copies the kickstart files into the project root
  - `all-sites-drush` - Executes drush commands across all defined sites
  - `solr-sync` - Syncs Solr configuration (requires ddev-solr and search_api_solr_admin)
  - `includes/aljibe_includes` - Shared bash functions used by multiple commands
  - `includes/os-detector` - Sets `DETECTED_SO` (linux/mac) for scripts and hooks that source it
- `commands/db/`: Execute in database container
  - `create-database` - Creates secondary databases for multisite setups

## Common Development Commands

### Initial Setup

```bash
# Setup environment and install site(s)
ddev setup

# Setup all sites (multisite)
ddev setup --all

# Setup without installing sites
ddev setup --no-install

# Setup without processing themes
ddev setup --no-themes

# Setup specific sites
ddev setup --sites=site1,site2

# Install all sites in parallel, in batches of 3
ddev setup --all --parallel=3
```

The `setup` command:
1. Runs `pre_setup` hooks
2. Executes `composer install`
3. Initializes GrumPHP
4. Builds frontend themes (unless `--no-themes`)
5. Installs sites (unless `--no-install`)
6. Runs `post_setup` hooks

### Site Installation

```bash
# Install site from configuration
ddev site-install [site_name]

# Install site from database dump
ddev site-install [site_name] [db_file.sql]

# Install site from database dump and files archive (tar.gz, tgz or zip)
ddev site-install [site_name] [db_file.sql] [files.tar.gz]
```

The `site-install` command:
- Uses drush aliases (appends `.local` if no dot in name)
- Sources `site-profiles` file to determine Drupal profile
- Creates secondary databases for multisite automatically
- Handles Redis and settings.local.php configuration
- Supports hooks: `pre_site_install`, `post_site_install`, `pre_site_install_config`, `post_site_install_config`, `pre_site_install_db`, `post_site_install_db`

### Testing Commands (in generated projects)

```bash
# Behat tests (folder must exist in tests/behat/)
ddev behat [local|pro|other_folder] [behat_options]
# Example: ddev behat local --profile=default

# BackstopJS visual regression
ddev backstopjs [local|pro|other_folder] [backstop_command]
# Example: ddev backstopjs local test
# Example: ddev backstopjs pro reference

# Pa11y accessibility tests
ddev pa11y [site_url]
# Example: ddev pa11y http://web
```

### Frontend Theme Development

```bash
# Build production assets for all themes
ddev frontend production

# Build specific theme
ddev frontend production [theme_name]

# Watch mode for development
ddev frontend watch [theme_name]

# Any npm script can be executed
ddev frontend [npm_script_name] [theme_name]
```

The frontend command (`commands/web/frontend`):
- Reads theme paths from `aljibe.yaml` using yq
- Runs `npm install` in theme directory
- Executes npm scripts defined in theme's package.json
- The theme name must match a key in `theme_paths` exactly
- First parameter is the npm script name (production, watch, dev, etc.)
- Second parameter is optional theme name; if omitted, processes all themes

### Multisite Management

```bash
# Run drush command on all sites
ddev all-sites-drush [drush_command]

# Create secondary database (letters, numbers, '_' and '-' only)
ddev create-database [db_name]
```

### Other Commands

```bash
# Get configuration from aljibe.yaml
ddev aljibe-config [key]
# Example: ddev aljibe-config theme_paths
# Example: ddev aljibe-config default_site

# Sync Solr configuration (requires ddev-solr addon and search_api_solr_admin module)
ddev solr-sync [solr_server]
```

## Hooks System

Aljibe provides extensive hooks in `aljibe.yaml` for customization:

**Setup hooks:**
- `pre_setup`, `post_setup`
- Available variables: `NO_THEMES`, `NO_INSTALL`, `SITES`, `CONFIG_DEFAULT_SITE`, plus all DDEV variables

**Site installation hooks:**
- `pre_site_install`, `post_site_install`
- `pre_site_install_config`, `post_site_install_config` (config-based installation)
- `pre_site_install_db`, `post_site_install_db` (database import installation)
- Available variables: `DRUPAL_PROFILE`, `SITE_PATH`, `SITE_ALIAS`, plus all DDEV variables

Hooks run through `eval` inside the calling script, so they also see variables set by the sourced includes (e.g. `DETECTED_SO`).

## Important Implementation Details

### Drush Aliases
- Site names without dots are automatically appended with `.local` for drush aliases (`self` is kept as is)
- Use exact alias names (including suffix) if not using `.local` convention
- `site-install` rejects remote aliases (`drush sa --fields=host`) **before** dropping any database
- It then drops the database before running `drush status`, because `status` bootstraps Drupal and can fail after switching branches; the alias existence check runs after the drop

### Multisite Database Management
- Default site uses database name "db"
- Additional sites use "db_[sitename]" (alphanumeric only)
- Each site gets its own `settings.ddev.php` with correct database reference
- Secondary databases are created automatically during site-install if needed
- `create-database` grants access to existing 'db' user

### Theme Processing
- All themes defined in `aljibe.yaml` must have a `package.json` with npm scripts
- The `frontend` command can execute any npm script, not just predefined ones
- Multiple themes are processed sequentially in setup
- Theme paths are read from aljibe.yaml using yq

### Testing Structure (in generated projects)
- Tests are located in the project's `tests/` directory (not project root)
- Behat configuration uses subfolders (tests/behat/local, tests/behat/pro, etc.)
- Base URL for tests is `https://web` (not apache or nginx) - see `kickstart/common/tests/behat/local/behat.yml`
- Behat uses Selenium hub at http://hub:4444/wd/hub for JavaScript tests
- Common features shared across environments are in tests/behat/common/features/

### Configuration Reading
- All configuration is read from .ddev/aljibe.yaml using the `aljibe-config` command
- The aljibe-config command uses yq (mikefarah v4, inside the web container) to parse YAML
- Configuration supports dot notation for nested values (e.g., `hooks.pre_setup`)
- Missing keys return an empty string; an invalid aljibe.yaml makes `aljibe-config` fail

### Static Analysis and Code Quality (in generated projects)
- Configured by `kickstart/common/grumphp.yml`; GrumPHP runs via DDEV with `EXEC_GRUMPHP_COMMAND: ddev exec php`
- GrumPHP enforces commit message format: "Issue #123: Description"
- Branch naming convention enforced: feature/, bugfix/, hotfix/, or develop only
- PHPStan, PHPCS (Drupal standards), PHPMD, and multiple linters run on commit
- PHPQA provides manual/CI execution of same tools for consistency

## Working With This Repository

### Testing This Add-on

See `TESTING.md` for details. Two kinds of BATS tests live in `tests/`:

- **Unit tests** (every `tests/*.bats` except `tests/test.bats`): run the real scripts in `commands/` against stub binaries (`ddev`, `mysql`, `npm`...) placed first in `PATH`. No DDEV or Docker needed; they take seconds.

  ```bash
  ls tests/*.bats | grep -v '/test.bats$' | xargs bats
  ```

  `tests/frontend.bats` and `tests/aljibe-config.bats` need mikefarah yq v4 (local binary or the `mikefarah/yq:4` Docker image) and skip otherwise.

- **Integration tests** (`tests/test.bats`): create and start real DDEV projects; slow. Never run `bats tests/*.bats` expecting only unit tests, since the glob includes this file.

When fixing a bug in a command, add a unit test that fails without the fix and passes with it. Skip tests for purely cosmetic changes.

### Testing Changes in a Real Project
1. Make changes to commands, scripts, or kickstart files in this repository
2. In a test Drupal project, run `ddev add-on get /path/to/this/repo` to install the local version
3. Test the changes in the Drupal project
4. Use `ddev start` to restart DDEV and reload commands after changes

### Command Development
- Commands are bash scripts with special DDEV comment headers
  - `## Description:` - Short description for help text
  - `## Usage:` - Usage pattern
  - `## Example:` - Example command
  - `## Flags:` - JSON array of flag definitions (optional)
- Commands must be executable (`chmod +x`, mode `100755` in git)
- Tag with `#ddev-generated` to indicate Aljibe-managed files

### Bash Conventions
- Keep `commands/` clean under shellcheck: `find commands -type f ! -name .gitkeep | xargs shellcheck -x` (the repo `.shellcheckrc` sets `source-path=SCRIPTDIR`; add `# shellcheck source=...` above `source` lines)
- Quote every variable expansion, especially paths; pass arguments through as `"$@"` / `"${@:2}"`, never via a flattened string
- Host commands must work on macOS too: BSD `chmod`/`sed`/`cp` and `/bin/bash` 3.2
  - `chmod -R mode path` (options first), `sed -i.bak ... && rm file.bak` for in-place edits
  - Copy directory contents with `cp -Rf "src/." "dst/"`, not `src/*` or `src/.*`
- Exit non-zero on every error path (usage errors, missing prerequisites)
- Never build SQL or yq expressions from unvalidated user input

### Kickstart Template Development
- Files in `kickstart/common/` are copied to all new projects
- Drupal version-specific files go in `kickstart/d10/` or `kickstart/d11/`
- Example files use `.example` suffix and are documented in README
- Templates may include placeholders for ddev-aljibe-assistant to replace

### Bash Helper Functions
- Add reusable bash functions to `commands/host/includes/aljibe_includes`
- Source the file in commands: `source "$(dirname "$0")/includes/aljibe_includes"`
- Common functions: `star_project()`, `run_hooks()`, `run_commands()`, `get_all_installable_sites()`, `install_sites_parallel()`, `get_database_name()`

## Key Files for Understanding

- `commands/host/setup` - Main setup orchestration
  - Handles flags: --all, --no-install, --no-themes, --sites, --themes, --parallel
  - Executes: pre_setup hooks → composer install → grumphp init → frontend builds → site installs → post_setup hooks
- `commands/host/site-install` - Site installation logic with config vs db modes
  - Two modes: config (using drush site:install + config-import) or db (using import-db + drush deploy)
  - Creates secondary databases automatically for non-default sites
  - Handles settings.ddev.php, settings.local.php, and Redis configuration
- `commands/host/includes/aljibe_includes` - Shared helper functions
  - `star_project()` - Ensures DDEV project is running before command execution
  - `run_hooks()` - Executes hook commands from aljibe.yaml
  - `run_commands()` - Executes array of commands with output
  - `get_all_installable_sites()` - Returns list of sites for --all flag
  - `install_sites_parallel()` - Installs sites in parallel batches for `setup --parallel`
- `commands/web/frontend` - Frontend asset processing
  - Uses yq to read theme_paths from aljibe.yaml
  - Runs npm install + npm run $TASK for each theme
- `commands/web/behat` - Behat test execution
  - First parameter is environment folder (default: local)
  - Remaining parameters passed to behat command
  - Config path: /var/www/html/tests/behat/$FOLDER/behat.yml
- `install.yaml` - DDEV add-on metadata and post-install actions
  - Runs aljibe-install-dependencies.sh to install dependent add-ons
  - Creates aljibe.yaml from example if not exists
  - Optionally installs ddev-aljibe-assistant
- `scripts/aljibe-install-dependencies.sh` - Dependency add-on management
  - Installs core add-ons: adminer, mkdocs, backstopjs, selenium, pa11y, unlighthouse, newman
  - Installs redis if memcached not present
  - On updates, only reinstalls already-installed add-ons
- `site-profiles` - Drupal profile selection for site installations
  - Sourced by site-install command before installation
  - Sets DRUPAL_PROFILE variable based on site name
  - Allows different profiles for different sites in multisite setups
- `aljibe.yaml.example` - Template configuration file
  - Defines default_site, theme_paths, installable_sites_aliases, hooks
  - Copied to aljibe.yaml on first installation
- `kickstart/` - Starter templates for new projects
  - `kickstart/common/` - Shared files (settings, tests, drush, grumphp)
  - `kickstart/d10/` - Drupal 10 composer.json
  - `kickstart/d11/` - Drupal 11 composer.json
  - Used by ddev-aljibe-assistant and `ddev aljibe-kickstart` to bootstrap new projects
