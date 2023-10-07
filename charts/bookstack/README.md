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

## Upgrade
It is recommended to make a backup of mariadb database and also configuration files used by bookstack on it's pvc. 

See _Backup and Restore_ section for more details. After doing so, you can upgrade via helm.
```
helm upgrade bookstack homeylab/bookstack -n bookstack

# with own values file - recommended
helm upgrade -f my-values.yaml bookstack homeylab/bookstack -n bookstack
```

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

A valid configuration should be provided and in most cases, a valid object storage provider configuration for remote archiving. Credentials can be specified directly in the config section or via `fileBackups.existingSecret`, see [here](https://github.com/homeylab/bookstack-file-exporter#authentication) for more information on getting/setting credentials for exporting. 

Example configuration below using minio:
```yaml
fileBackups:
    config: |
        ## The target bookstack instance
        ## example value shown below
        host: "bookstack.bookstack.svc.cluster.local"

        ## if existingSecret is supplied, can omit/comment out the `credentials` section below
        credentials:
        token_id: XXXXXXXXXXXXXXXXXXXX
        token_secret: YYYYYYYYYYYYYYYYYY

        ## provide additional headers
        ## comment out section if not needed
        additional_headers:
          User-Agent: "helm-bookstack"

        ## export formats (multiple options can be chosen)
        formats:
        - markdown
        # - html
        # - pdf
        # - plaintext

        ## export json metadata about the page
        export_meta: false

        ## remove from local volume/disk after upload to object storage
        clean_up: true

        ## see minio config section for details: https://github.com/homeylab/bookstack-file-exporter#minio-backups
        ## omit/comment out if using a different object storage provider
        minio_config:
            host: "minio.test.org"
            # if existingSecret is supplied, can omit the `*_key` sections below
            access_key: MMMMMMMMMMMM
            secret_key: QQQQQQQQQQQQQQQQQQ
            # required by minio
            # if unsure, try "us-east-1"
            region: "us-east-1"
            # bucket to use
            bucket: "bookstack"
            # path to upload to
            # optional, will use root bucket path if not set
            # the exported archive will appear in: `<bucket_name>:<path>/bookstack_export_<timestamp>.tgz`gz`
            path: "bookstack/file_backups/"
        
        # s3_config:
```

To use this feature, set `fileBackups.enabled` to `true`. For more information on how to set configuration options, see exporter [docs](https://github.com/homeylab/bookstack-file-exporter#configuration).

## Backup And Restore Of MariaDB
When upgrading to different versions, you should do a back up of your mariadb data and have that available just in case. This can be used for other situations like PVC resizing as well.
- Stop bookstack pod
```
kubectl scale deploy -n bookstack bookstack --replicas=0
```
- Do a backup of mariadb bookstack db
```
# get into container
$ k exec -it -n bookstack bookstack-mariadb-0 bash

# dump
$ mariadb-dump -A -u root -p bookstack > backup.sql

# check dump
$ md5sum backup.sql

# copy dump to local and do a md5sum check
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