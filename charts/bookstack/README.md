
# Bookstack
![Version: 4.1.0](https://img.shields.io/badge/Version-3.1.0-informational?style=flat-square) ![Type: application](https://img.shields.io/badge/Type-application-informational?style=flat-square) ![AppVersion: version-v24.12](https://img.shields.io/badge/AppVersion-version--v24.05.2-informational?style=flat-square)

Table of Contents
- [Bookstack](#bookstack)
  - [Add Chart Repo](#add-chart-repo)
  - [Prerequisites](#prerequisites)
  - [Install](#install)
  - [Upgrades](#upgrades)
  - [Configuration Options](#configuration-options)
  - [Bookstack File Exporter (Backup Your Pages)](#bookstack-file-exporter-backup-your-pages)
  - [Backup And Restore Of MariaDB](#backup-and-restore-of-mariadb)

This chart deploys [bookstack](https://github.com/BookStackApp/BookStack), an app for self and/or collaborated documentation similar to confluence. This chart includes an option to install mariadb alongside it (default: enabled) and an exporter for file backups.

*Note: You should set some chart values by creating your own values.yaml and save that locally*

## Add Chart Repo
```bash
helm repo add homeylab https://homeylab.github.io/helm-charts/
# update the chart, this can also be run to pull new versions of the chart for upgrades
helm repo update homeylab
```

## Prerequisites
Ensure you either enable mariadb dependency, `mariadb.enabled`, or have an existing compatible DB server ready for bookstack. 

This chart provides the option to install mariadb by default from [bitnami](https://github.com/bitnami/charts/tree/main/bitnami/mariadb).

## Install
```bash
helm install bookstack homeylab/bookstack -n bookstack --create-namespace

# with own values file - recommended
helm install -f my-values.yaml bookstack homeylab/bookstack -n bookstack --create-namespace
```

#### OCI Registry Support
```bash
helm install bookstack -n bookstack oci://registry-1.docker.io/homeylabcharts/bookstack --version X.Y.Z --create-namespace

# with own values file - recommended
helm install -f my-values.yaml bookstack -n bookstack oci://registry-1.docker.io/homeylabcharts/bookstack --version X.Y.Z --create-namespace
```

### Install Example
Only some options are shown, view `values.yaml` for an exhaustive list. You can add/change more properties as needed.

Click below to expand for an example of a valid `custom-values.yaml` file. 
<details closed>
<summary>custom-values.yaml</summary>
<br>

```yaml
# custom-values.yaml
config:
  appUrl: "https://bookstack.somedomain"
  appKey: "base64:MywekbncHHu+a3R/gGTT7wwnUQGc6o9PXWrVOyaHlp4="
  ## Default values below will work with included mariadb chart in bookstack namespace
  dbHost: bookstack-mariadb.bookstack.svc.cluster.local
  dbPort: 3306
  dbDatabase: bookstack
  dbUser: sampleuser
  dbPass: samplepass
  cacheDriver: database
  sessionDriver: database

extraEnv:
  TZ: Etc/UTC
  APP_DEFAULT_DARK_MODE: true
  APP_VIEWS_BOOKS: list

ingress:
  enabled: true
  className: "nginx"
  annotations:
    nginx.ingress.kubernetes.io/proxy-connect-timeout: "36000"
    nginx.ingress.kubernetes.io/proxy-read-timeout: "36000"
    nginx.ingress.kubernetes.io/proxy-send-timeout: "36000"
    cert-manager.io/cluster-issuer: "letsencrypt-issuer"
    nginx.ingress.kubernetes.io/ssl-redirect: "true"
    nginx.ingress.kubernetes.io/force-ssl-redirect: "true"
  hosts:
    - host: bookstack.somedomain
      paths:
        - path: /
          pathType: Prefix

persistence:
  enabled: true
  storageClass: ""
  size: 5Gi
  accessModes:
    - ReadWriteOnce

## https://github.com/bitnami/charts/tree/main/bitnami/mariadb
## some basic options below but look at their chart for more
mariadb:
  enabled: true
  architecture: standalone
  auth:
    rootPassword: "root"
    existingSecret: ""
    database: "bookstack"
    username: "sampleuser"
    password: "samplepass"
  primary:
    persistence:
      enabled: true
      storageClass: ""
      accessModes:
        - ReadWriteOnce
      size: 5Gi
  metrics:
    enabled: true
    serviceMonitor:
      enabled: true
      labels:
        app: mariadb
```
</details>
<br>

Install with custom:
```bash
helm install -f custom-values.yaml bookstack homeylab/bookstack -n bookstack --create-namespace
```

## Upgrades
It is recommended to make a backup of mariadb database and also configuration files used by bookstack on it's pvc. See _Backup and Restore_ section for more details.

For additional steps that need to be done for upgrade, check upstream dependencies:
1. For Bookstack upgrade steps, check the [documentation](https://www.bookstackapp.com/docs/admin/updates/).
2. If using the Mariadb instance provided in this chart, follow Mariadb chart [upgrade](https://github.com/bitnami/charts/tree/main/bitnami/mariadb#upgrading) steps for DB upgrades and follow official Mariadb [guides](https://mariadb.com/kb/en/upgrading/).

```bash
helm upgrade bookstack homeylab/bookstack -n bookstack

# with own values file - recommended
helm upgrade -f my-values.yaml bookstack homeylab/bookstack -n bookstack
```

#### OCI Registry Support
```bash
helm upgrade bookstack -n bookstack oci://registry-1.docker.io/homeylabcharts/bookstack --version X.Y.Z

# with own values file - recommended
helm upgrade -f my-values.yaml bookstack -n bookstack oci://registry-1.docker.io/homeylabcharts/bookstack --version X.Y.Z
```

#### Upgrade Matrix For Releases
_The matrix below displays certain versions of this helm chart that could result in breaking changes._

| Start Chart Version | Target Chart Version | Upgrade Steps |
| ------------------- | -------------------- | ------------- |
| `3.X.X` | `4.0.0` | Bookstack version is updated to `v24.10` from `v24.05.2`. The docker image from `linuxserver/bookstack` introduces the requirement for an appKey to be set in the `config` section. This will required to be set by the user, see [here](https://github.com/linuxserver/docker-bookstack?tab=readme-ov-file#parameters) for more information or Configuration section below. `DB_USER` and `DB_PASS` env variables have been changed to `DB_USERNAME` and `DB_PASSWORD` for those that use the `existingSecret` option. |
| `2.8.X` | `3.0.0` | Optional embedded mariadb chart version is updated to `18.0.2` from `14.1.4`. Check upstream upgrade [notes](https://github.com/bitnami/charts/tree/main/bitnami/mariadb#upgrading) for any potential issues before upgrading. If additional options are used for the embedded Mariadb section in the `values.yaml` file, configuration may need to be adjusted based on chart changes. Mariadb version itself stays on a `11.3.X` release. |
| `2.4.X` | `2.5.0` | File exporter has been upgraded to `1.0.0` which has some breaking configuration changes. |
| `2.2.X` | `2.3.X` | A new configuration option for application url, has been implemented in `config.appUrl` and should be used instead of placing it in the `extraEnv` section (`APP_URL`) for consistency purposes. |

#### Nginx Configuration Warnings
After certain upgrades, you may see warnings in the logs about nginx configuration mismatches. 
```
**** The following active confs have different version dates than the samples that are shipped. ****
**** This may be due to user customization or an update to the samples. ****
**** You should compare the following files to the samples in the same folder and update them. ****
**** Use the link at the top of the file to view the changelog. ****
┌────────────┬────────────┬────────────────────────────────────────────────────────────────────────┐
│  old date  │  new date  │ path                                                                   │
├────────────┼────────────┼────────────────────────────────────────────────────────────────────────┤
│ 2024-05-27 │ 2024-07-16 │ /config/nginx/site-confs/default.conf                                  │
└────────────┴────────────┴────────────────────────────────────────────────────────────────────────┘
```

Linuxserver.io changes their base Nginx configuration at times and it may have drifted. You can either find the new versions being referenced [here](https://github.com/linuxserver/docker-baseimage-alpine-nginx) or if your environment has access, it can be pulled. You can then copy the new version using `kubectl cp` to the pod and replace the old version. To re-pull it on start up, you can delete the file. Either option will require a restart of the pod to take effect.

```bash
# example of deleting for a re-pull
kubectl exec -it -n bookstack {{ pod_name }} -- bash -c "rm /config/nginx/site-confs/default.conf"

# example of copying a new version
kubectl cp default.conf bookstack/{{ pod_name }}:/config/nginx/site-confs/default.conf
```

## Configuration Options
For a full list of options, see `values.yaml` file.

| property | description | default |
| -------- | ----------- | ------- |
| `existingSecret` | Specify the name of an existing secret that contains the following keys: `DB_USERNAME`, `DB_PASSWORD`, and `APP_KEY`. If specified, the options `config.dbUser`, `config.dbPassword`, and `config.appKey` will be ignored. | `""` |
| `config.appUrl` | Specify the url (with http/https) used to access Bookstack instance, example: `https://bookstack.domain.org` | `""` |
| `config.appKey` | Required as of chart version `4.X.X` or higher. Specify the app key for the bookstack instance, required for newer versions of the `linuxserver/bookstack` image. Generate one with: `docker run -it --rm --entrypoint /bin/bash lscr.io/linuxserver/bookstack:latest appkey`. This is ignored if `existingSecret` is specified. *You should generate a new one for your instance* but an example is provided. | `base64:MywekbncHHu+a3R/gGTT7wwnUQGc6o9PXWrVOyaHlp4=` |
| `config.dbHost` | Which backend db to use, if empty string, will attempt to use embedded chart mariaDB service. | `bookstack-mariadb.bookstack.svc.cluster.local`|
| `config.dbPort` | Specify the port for the backend db. | `3306` |
| `config.dbDatabase` | Which database to use when connected to the backend db. | `bookstack` | 
| `config.dbUser` | Username for db connection, will be ignored if `existingSecret` is given | `bookstack` |
| `config.dbPassword` | Password for db connection, will be ignored if `existingSecret` is given | `bookstack` |
| `config.cacheDriver` | Which driver to use for cache. Valid values: `'file', 'database', 'memcached' or 'redis` | `database` |
| `config.sessionDriver` | Which driver to use for sessions. Valid values: `'file', 'database', 'memcached' or 'redis` | `database` |

For more configuration option, refer to the documented env variables available for bookstack [here](https://github.com/BookStackApp/BookStack/blob/development/.env.example.complete).

Additional configuration can be specified in the `extraEnv` section, some examples:
```yaml
extraEnv:
  TZ: Etc/UTC
  APP_DEFAULT_DARK_MODE: true
  APP_VIEWS_BOOKS: list
```

## Bookstack File Exporter (Backup Your Pages)
This chart includes an optional [exporter](https://github.com/homeylab/bookstack-file-exporter) that will archive all your pages and their contents to a supported object storage provider(s) like minio, s3, etc.

This exporter creates a `.tgz` archive in a folder-tree layout to maintain the hierarchy of shelves, books, and pages. Including the option to export media such as images and attachments.

The exporter is included as an optional dependency from a different helm [chart](https://github.com/homeylab/helm-charts/tree/main/charts/bookstack-file-exporter) and is enabled by setting `bookstack-file-exporter.enabled`.

See the source helm chart for more information on configuration.

## Backup And Restore Of MariaDB
When upgrading to different versions, you can do a back up of your mariadb data and bookstack files to have available just in case. This can be used for other situations like PVC resizing as well. Below is just an example for a small set up but there any other ways to do this as well like PV backups via [Longhorn](https://longhorn.io/docs/latest/) as an example.

For more information on backup/restore steps, you should follow the documentation for upstream providers: 

1. [bookstack](https://www.bookstackapp.com/docs/admin/backup-restore/)
2. [mariadb](https://mariadb.com/kb/en/full-backup-and-restore-with-mariabackup/)

Example for a small mariadb set up:
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