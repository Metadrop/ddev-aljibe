# Testing ddev-aljibe

This document describes how to test the ddev-aljibe add-on during development.

## Overview

The ddev-aljibe add-on uses [BATS (Bash Automated Testing System)](https://github.com/bats-core/bats-core) for testing. Tests are executed automatically via GitHub Actions on pull requests, pushes to main, and daily scheduled runs.

It relies in ddev-aljibe-assistant and many tests use the assistant to perform installations and configurations.

## Test Structure

```
tests/
└── test.bats          # Main test file with installation tests
```

## Running Tests Locally

### Prerequisites

- DDEV installed (v1.24.0+)
- Docker running (24+)
- BATS installed

### Installing BATS

**macOS:**
```bash
brew install bats-core
```

**Linux:**
```bash
# Ubuntu/Debian
sudo apt-get install bats

# Or install from source
git clone https://github.com/bats-core/bats-core.git
cd bats-core
sudo ./install.sh /usr/local
```

### Running the Test Suite

From the repository root:

```bash
# Run all tests
bats tests/test.bats

# Run with verbose output
bats tests/test.bats -t

# Run specific test
bats tests/test.bats -f "install from directory"
```

### Running the Unit Tests

The other `tests/*.bats` files are unit tests for the scripts in `commands/`. They run the real scripts against stub binaries (`ddev`, `mysql`, `npm`...) placed first in `PATH`, so they need neither DDEV nor Docker and finish in seconds.

```bash
# Run all unit tests (excludes the DDEV integration suite in tests/test.bats)
ls tests/*.bats | grep -v '/test.bats$' | xargs bats

# Run a single unit test file
bats tests/site-install.bats
```

Do not use `bats tests/*.bats` for this: the glob also matches `tests/test.bats`, which creates and starts real DDEV projects.

`tests/frontend.bats` and `tests/aljibe-config.bats` need mikefarah yq v4 (as used in the DDEV web container), either as a local `yq` binary or as the `mikefarah/yq:4` Docker image. They are skipped when neither is available.

### Understanding Test Output

Tests use file descriptor 3 (`>&3`) for diagnostic output that appears with `-t` flag:

```bash
# This shows detailed check output
bats tests/test.bats -t
```

## Current Test Coverage

### Installation Tests

1. **install from directory** - Tests local development installation
   - Installs add-on from local directory
   - Runs aljibe-assistant in auto mode
   - Checks installed services
   - Verifies project is browsable

2. **install from release** - Tests production installation
   - Installs add-on from GitHub release
   - Runs aljibe-assistant in auto mode
   - Checks installed services
   - Verifies project is browsable

### Test Helpers

- `check_services()` - Verifies expected DDEV add-ons are installed
- `check_project_browse()` - Ensures Drupal site is accessible
- `check_drupal_admin_access()` - Validates admin login (currently disabled)

## Known Issues

### Disabled Tests

The `check_drupal_admin_access()` test is currently commented out in both test cases due to implementation issues. This needs to be fixed to improve coverage.

### Test Limitations

Current tests only verify:
- Add-on installation succeeds
- Dependent add-ons are installed
- Drupal site becomes accessible

They do NOT test:
- Custom DDEV commands (setup, site-install, frontend, behat, etc.)
- Configuration file reading (aljibe.yaml)
- Hooks system functionality
- Multisite capabilities
- Theme building
- Testing tool integration (Behat, BackstopJS, Pa11y, etc.)

## GitHub Actions Integration

Tests run automatically via `.github/workflows/tests.yml`:

### Triggers

- Pull requests
- Pushes to `main` branch
- Daily at 7:00 AM UTC (schedule)
- Manual workflow dispatch with optional tmate debugging

### Jobs

1. **code_quality** - Runs ShellChecker on shell scripts
2. **tests** - Executes BATS test suite using `ddev/github-action-add-on-test@v2`

### Debugging CI Tests

Enable tmate debugging session in GitHub Actions:

1. Go to Actions → tests workflow
2. Click "Run workflow"
3. Check "Debug with tmate"
4. Click "Run workflow"
5. Wait for tmate session URL in logs

## Writing New Tests

### BATS Test Structure

```bash
@test "descriptive test name" {
  set -eu -o pipefail
  cd "$TESTDIR"

  # Test commands
  ddev some-command

  # Assertions - must return non-zero on failure
  run ddev aljibe-config default_site
  [ "$status" -eq 0 ]
  [[ "$output" =~ "default" ]]
}
```

### Best Practices

1. **Use setup/teardown** - Already provided, creates/destroys test project
2. **Explicit assertions** - Use `[ ]`, `[[ ]]`, or `run` with status checks
3. **Diagnostic output** - Use `>&3` for debug info visible with `-t`
4. **Fail fast** - Set `set -eu -o pipefail` at test start
5. **Cleanup** - teardown() handles cleanup, but clean up within tests too
6. **Isolation** - Each test should be independent

### Example: Testing a Custom Command

```bash
@test "setup command installs drupal" {
  set -eu -o pipefail
  cd "$TESTDIR"

  # Install add-on
  ddev get "${DIR}"
  ddev restart >/dev/null
  ddev aljibe-assistant --auto

  # Test setup command
  echo "# Running ddev setup" >&3
  run ddev setup --no-themes

  # Assertions
  [ "$status" -eq 0 ]

  # Verify Drupal is installed
  run ddev drush status --field=bootstrap
  [ "$status" -eq 0 ]
  [[ "$output" =~ "Successful" ]]
}
```

### Adding Test Fixtures

Create sample configurations for testing:

```bash
tests/
├── test.bats
└── fixtures/
    ├── aljibe.yaml.simple       # Minimal config
    ├── aljibe.yaml.multisite    # Multi-site config
    └── aljibe.yaml.with-hooks   # Config with hooks
```

Use in tests:
```bash
@test "aljibe-config reads configuration" {
  cp tests/fixtures/aljibe.yaml.simple .ddev/aljibe.yaml
  ddev restart

  run ddev aljibe-config default_site
  [ "$status" -eq 0 ]
  [ "$output" = "default" ]
}
```

## Test Development Workflow

### 1. Local Development

```bash
# Make changes to commands, scripts, or tests
vim commands/host/setup

# Run tests
bats tests/test.bats -t

# Debug specific test
bats tests/test.bats -f "install from directory" -t
```

### 2. Testing in Real Project

```bash
# In a test Drupal project directory
ddev get /path/to/ddev-aljibe
ddev restart

# Test the changes manually
ddev setup --all
ddev frontend production
ddev behat local
```

### 3. Verify CI

Push changes and check GitHub Actions for CI test results.

## Planned Improvements

### High Priority

1. Fix `check_drupal_admin_access()` test
2. Make helper functions return proper exit codes
3. Add tests for core commands (setup, site-install, frontend)
4. Split tests into multiple BATS files by functionality

### Medium Priority

5. Add integration tests for command chains
6. Test configuration reading (aljibe-config command)
7. Test hooks system
8. Add multisite test scenarios
9. Verify dependent add-ons are functional, not just installed

### Low Priority

10. Add fixtures for various aljibe.yaml configurations
11. Mock/stub where possible to speed up tests
12. Test theme building functionality
13. Add tests for all testing tool integrations

## Troubleshooting

### Tests Fail Locally But Pass in CI

- Ensure DDEV is up to date (`ddev version`)
- Check Docker is running and healthy
- Clean up any stale test projects: `ddev delete -Oy test-addon-aljibe`
- Remove test directory: `rm -rf ~/tmp/test-addon-aljibe`

### Tests Take Too Long

Current tests install full Drupal sites, which is slow. Future improvements should:
- Mock where possible
- Split into fast unit tests and slow integration tests
- Cache common setup steps

### BATS Not Found

Install BATS (see Prerequisites section above).

### Permission Issues

Ensure test scripts are executable:
```bash
chmod +x tests/*.bats
```

## Resources

- [BATS Core Documentation](https://bats-core.readthedocs.io/)
- [DDEV Add-on Testing Guide](https://ddev.readthedocs.io/en/stable/developers/add-ons/#testing-add-ons)
- [ddev/github-action-add-on-test](https://github.com/ddev/github-action-add-on-test)
- [ShellCheck](https://www.shellcheck.net/) - Shell script linter used in CI

## Contributing

When adding new features to ddev-aljibe:

1. Write tests for new commands or functionality
2. Ensure existing tests still pass
3. Update this documentation if adding new test files or patterns
4. Run shellcheck on any new shell scripts: `shellcheck commands/host/new-command`

Tests help ensure ddev-aljibe works reliably across different environments and DDEV versions.
