# Bookstack
This chart deploys bookstack, an app for self and/or collaborated documentation similar to confluence. This chart includes an option to install mariadb alongside it, enabled by default.

*Note: You should set some chart values by creating your own values.yaml and save that locally*

## Add Chart Repo
```
helm repo add homeylab https://homeylab.github.io/helm-charts/
helm repo update homeylab
```

## Prerequisites
Ensure you either enable mariadb dependency, `mariadb.enabled`, or have an existing compatible DB server ready for bookstack. 

This chart provides the option to install mariadb by default from [bitnami](https://github.com/bitnami/charts/tree/main/bitnami/mariadb).

## Install
**Note it is recommended to set your own variables as required and store them in a custom values.yaml file.**
```
helm install bookstack homeylab/bookstack -n bookstack --create-namespace

# with own values file - recommended
helm install -f my-values.yaml bookstack homeylab/bookstack -n bookstack --create-namespace
```

## Upgrades
It is recommended (but not required) to make a backup of mariadb database and also configuration files used by bookstack on it's pvc. See _Backup and Restore_ section for more details.

Steps:
```bash
helm upgrade bookstack homeylab/bookstack -n bookstack

# with own values file - recommended
helm upgrade -f my-values.yaml bookstack homeylab/bookstack -n bookstack
```

For additional steps that need to be done for upgrade, check upstream dependencies:

1. For Bookstack upgrade steps, check the [documentation](https://www.bookstackapp.com/docs/admin/updates/).
2. If using the Mariadb instance provided in this chart, follow Mariadb chart [upgrade](https://github.com/bitnami/charts/tree/main/bitnami/mariadb#upgrading) steps for DB upgrades and follow official Mariadb [guides](https://mariadb.com/kb/en/upgrading/).

## Configuration Options
Specify required configuration in the `config` section of your _values.yaml_ file

| property | description | example |
| -------- | ----------- | ------- |
| `config.appUrl` | Specify the url (with http/https) used to access Bookstack instance | `https://bookstack.domain.org`|
| `config.dbHost` | Which backend db to use, if empty string, will attempt to use embedded mariaDB service | `bookstack-mariadb.bookstack.svc.cluster.local` |
| `config.dbPort` | Specify the port for the backend db. | `3306` |
| `config.dbDatabase` | Which database to use when connected to the backend db. | `bookstack` | 
| `config.dbUser` | Username for db connection, will be ignored if `existingSecret` is given | `bookstack` |
| `config.dbPassword` | Password for db connection, will be ignored if `existingSecret` is given | `bookstack` |
| `config.cacheDriver` | Which driver to use for cache. | `'file', 'database', 'memcached' or 'redis` |
| `config.sessionDriver` | Which driver to use for sessions. | `'file', 'database', 'memcached' or 'redis` |
| `config.dbPassword` | Password for db connection, will be ignored if `existingSecret` is given | `bookstack` |

For more configuration option, refer to the documented env variables available for bookstack [here](https://github.com/BookStackApp/BookStack/blob/development/.env.example.complete).

Additional configuration can be specified in the `extraEnv` section, some examples:
```yaml
extraEnv:
  TZ: Etc/UTC
  APP_DEFAULT_DARK_MODE: true
  APP_VIEWS_BOOKS: list
```

## File Exporter (Backup Your Pages)
This chart includes an optional [exporter](https://github.com/homeylab/bookstack-file-exporter) that will archive all your pages and their contents to a supported object storage provider(s) like minio, s3, etc.

This exporter creates a `.tgz` archive in a folder-tree layout to maintain the hierarchy of shelves, books, and pages.

Supported backup formats are shown [here](https://demo.bookstackapp.com/api/docs#pages-exportHtml) and below:

1. html
2. pdf
3. markdown
4. plaintext

A valid configuration should be provided and a valid object storage provider configuration(s) for remote archiving. Credentials can be specified directly in the config section or via `fileBackups.existingSecret`, see [here](https://github.com/homeylab/bookstack-file-exporter#authentication) for more information on getting/setting credentials for exporting. 

Example configuration below using minio, place inside `fileBackups.config` string block.
```yaml
# The target bookstack instance
# example value shown below
# if http/https not specified, defaults to https
# if you put http here, it will try verify=false, not to check certs
host: "https://bookstack.example.com"
# You could optionally set the bookstack token_id and token_secret here instead of env
# if existingSecret is supplied, can omit/comment out the `credentials` section below
credentials:
    # set here or as env variable, BOOKSTACK_TOKEN_ID
    # env var takes precedence over below
    token_id: ""
    # set here or as env variable, BOOKSTACK_TOKEN_SECRET
    # env var takes precedence over below
    token_secret: ""
# additional headers to add, examples below
# if not required, you can omit/comment out section
additional_headers:
  User-Agent: "helm-bookstack-exporter"
# supported formats from bookstack below
# specify one or more
# comment/remove the ones you do not need
formats:
  - markdown
  - html
  - pdf
  - plaintext
# if existingSecret is supplied, can omit/comment out the `minio_config._key` sections below
minio_config:
  # a host/ip + port combination is also allowed
  # example: "minio.yourdomain.com:8443"
  host: "minio.yourdomain.com"
  # set here or as env variable, MINIO_ACCESS_KEY
  # env var takes precedence over below
  access_key: ""
  # set here or as env variable, MINIO_SECRET_KEY
  # env var takes precedence over below
  secret_key: ""
  # required by minio
  # if unsure, try "us-east-1"
  region: "us-east-1"
  # bucket to use
  bucket: "bookstack-bkps"
  # path to upload to
  # optional, will use root bucket path if not set
  # the exported archive will appear in: `<bucket_name>:<path>/bookstack_export_<timestamp>.tgz`
  path: "bookstack/file_backups/"
  # optional if specified exporter can delete older archives
  # valid values are:
  # set to 1+ if you want to retain a certain number of archives
  # set to 0 or comment out section if you want no action done
  keep_last: 5
# optional export of metadata about the page in a json file
# this metadata contains general information about the page
# like: last update, owner, revision count, etc.
# omit this or set to false if not needed
export_meta: false
# optional if specified exporter can delete older archives
# valid values are:
# set to -1 if you want to delete all archives after each run
# - this is useful if you only want to upload to object storage
# set to 1+ if you want to retain a certain number of archives
# set to 0 or comment out section if you want no action done
keep_last: -1
```

To use this feature, set `fileBackups.enabled` to `true`. For more information on how to set configuration options, see exporter [docs](https://github.com/homeylab/bookstack-file-exporter#configuration).

## Backup And Restore Of MariaDB
When upgrading to different versions, you can do a back up of your mariadb data and bookstack files to have available just in case. This can be used for other situations like PVC resizing as well. Below is just an example but there any other ways to do this as well like PV backups via [Longhorn](https://longhorn.io/docs/latest/) as an example.

For more information on backup/restore steps, you should follow the documentation for upstream providers: 

1. [bookstack](https://www.bookstackapp.com/docs/admin/backup-restore/)
2. [mariadb](https://mariadb.com/kb/en/full-backup-and-restore-with-mariabackup/)

Example for mariadb:
- Stop bookstack pod
```
kubectl scale deploy -n bookstack bookstack --replicas=0
```
- Do a backup of mariadb bookstack db
```
# get into container
$ k exec -it -n bookstack bookstack-mariadb-0 bash

# dump
# root password is generated during install as a secret or user defined in the included mariadb instance
$ mariadb-dump -A -u root -p bookstack > backup.sql

# check dump
$ md5sum backup.sql

# copy dump to local and do a md5sum check
# or export to object storage/other if too large can try mounting PV with a utility pod after scaling mariadb down
$ kubectl cp bookstack/bookstack-mariadb-0:/tmp/backup.sql app_db_backup.sql
$ md5sum app_db_backup.sql
```
- Upgrade mariadb and/or bookstack version. Or doing another operation like PVC resizing, changing `storageClass`, etc.
    - You may have to scale down bookstack pod again if it is restarted during the upgrade.

- Then do a restore while bookstack pod is still down
```
# copy file to mariadb
$ kubectl cp app_db_backup.sql bookstack/bookstack-mariadb-0:/tmp/backup.sql
$ md5sum app_db_backup.sql

# restore
$ mysql -u root -p -D bookstack < backup.sql
```
- Scale back up bookstack and it should be reading from your initial database dataset

## Upgrade Matrix For Releases
_The matrix below displays certain versions of this helm chart that could result in breaking changes._

| Start Chart Version | Target Chart Version | Upgrade Steps |
| ------------------- | -------------------- | ------------- |
| `2.2.X` | `2.3.X` | A new configuration option for application url, has been implemented in `config.appUrl` and should be used instead of placing it in the `extraEnv` section (`APP_URL`) for consistency purposes. |