# Drupal configuration folder

Folder to store the Drupal configuration files. Configuration export and import is done from/to this folder.

- `default`: global configuration (all environments, and all sites if this is a multisite project).
- `envs`: per environment configuration. The [Configuration Split](https://www.drupal.org/project/config_split) module needs to be configured to use these folders.

- `envs/local`: place here the configuration for the local development environment.
- `envs/<environment>`: add more folder for other environments like ci, stage or prod.


For multisite projects, the recommendation is to create a `sites` folder. Inside create a folder for each site with two folders: `envs`and `common`, with the same function mentioned above.

Something like this:

```
- sites:
   - site1
     - default
     - envs
   - site2
     - default
     - envs
   - ...
   - site N
     - default
     - envs

```