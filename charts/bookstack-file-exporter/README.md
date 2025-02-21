# bookstack-file-exporter
![Version: 0.0.2](https://img.shields.io/badge/Version-0.0.1-informational?style=flat-square) ![Type: application](https://img.shields.io/badge/Type-application-informational?style=flat-square) ![AppVersion: 1.4.1](https://img.shields.io/badge/AppVersion-1.4.0-informational?style=flat-square)

- [bookstack-file-exporter](#bookstack-file-exporter)
  - [Add Chart Repo](#add-chart-repo)
  - [Install](#install)
  - [Upgrades](#upgrades)
  - [Configuration Options](#configuration-options)

This chart deploys [bookstack-file-exporter](https://github.com/homeylab/bookstack-file-exporter), an exporter that provides a way to export [Bookstack](https://github.com/BookStackApp/BookStack) pages and their content (_text, images, attachments, metadata, etc._) into a relational parent-child layout onto persistent volumes with an option to push to remote object storage locations. See source repository for more information on features and behavior of the exporter.

This chart is also included as an optional CronJob or Deployment in the [bookstack](https://github.com/homeylab/helm-charts/tree/main/charts/bookstack) helm chart.

## Add Chart Repo
```bash
helm repo add homeylab https://homeylab.github.io/helm-charts/
# update the chart, this can also be run to pull new versions of the chart for upgrades
helm repo update homeylab
```

## Install
```bash
helm install bookstack-file-exporter homeylab/bookstack-file-exporter -n bookstack --create-namespace

# with own values file - recommended
helm install -f my-values.yaml bookstack-file-exporter homeylab/bookstack-file-exporter -n bookstack --create-namespace
```

#### OCI Registry Support
```bash
helm install bookstack-file-exporter -n bookstack oci://registry-1.docker.io/homeylabcharts/bookstack-file-exporter --version X.Y.Z --create-namespace

# with own values file - recommended
helm install -f my-values.yaml bookstack-file-exporter -n bookstack oci://registry-1.docker.io/homeylabcharts/bookstack-file-exporter --version X.Y.Z --create-namespace
```

### CronJob or Deployment
Using the `runInterval` property (default: `0`), you can choose to deploy either a CronJob or Deployment resource. If specified (>`0`), exporter will run as a deployment and pause for `{run_interval}` seconds before subsequent runs. Example: `86400` seconds = `24` hours or run once a day.

If `runInterval` is default (`0`) value, a CronJob will be created instead and use `cron.schedule` for scheduling instead.

### Install Example
Only some options are shown, view `values.yaml` for an exhaustive list. You can add/change more properties as needed.

Click below to expand for an example of a valid `custom-values.yaml` file. 
<details closed>
<summary>custom-values.yaml</summary>
<br>

```yaml
extraEnv:
  LOG_LEVEL: info

config:
  host: "http://wiki.example.org"
  credentials:
    tokenId: "sample_tokenid"
    tokenSecret: "sample_tokensecret"
  additionalHeaders:
    User-Agent: "bookstack-file-exporter"
  formats:
    - markdown
    # - html
    # - pdf
    # - plaintext
  minio:
    enabled: false
    host: ""
    accessKey: ""
    secretKey: ""
    region: "us-east-1"
    bucket: ""
    path: ""
    keepLast: 5
  assets:
    exportImages: true
    exportAttachments: true
    modifyMarkdown: true
    exportMeta: false
    verifySSL: true
  keepLast: 3
  runInterval: 0

persistence:
  enabled: true
  annotations: {}
  storageClass: "sample-provisioner"
  size: 5Gi
  existingClaim: ""
  accessModes:
    - ReadWriteOnce
  mountPath: "/export/dump"
  selector: {}
```
</details>
<br>

Install with custom:
```bash
helm install -f custom-values.yaml bookstack-file-exporter homeylab/bookstack-file-exporter -n bookstack --create-namespace
```

## Upgrades
```bash
helm upgrade bookstack-file-exporter homeylab/bookstack-file-exporter -n bookstack

# with own values file - recommended
helm upgrade -f my-values.yaml bookstack-file-exporter homeylab/bookstack-file-exporter -n bookstack
```

#### OCI Registry Support
```bash
helm upgrade bookstack-file-exporter -n bookstack oci://registry-1.docker.io/homeylabcharts/bookstack-file-exporter --version X.Y.Z

# with own values file - recommended
helm upgrade -f my-values.yaml bookstack-file-exporter -n bookstack oci://registry-1.docker.io/homeylabcharts/bookstack-file-exporter --version X.Y.Z
```

### Upgrade Matrix For Releases
_The matrix below displays certain versions of this helm chart that could result in breaking changes._

## Configuration Options
For a full list of options, see `values.yaml` file.

For more information on all `config.*` properties and environment variables, see the source [documentation](https://github.com/homeylab/bookstack-file-exporter).

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| existingSecret | string | `""` | use an existing secret for credentials |
| extraEnv | object | `{}` | set extra environment variables |
| config.host | string | `"http://bookstack.bookstack.svc.cluster.local"` | set the bookstack instance URL |
| config.credentials.tokenId | string | `""` | set token id, ignored if `BOOKSTACK_TOKEN_ID` is defined in `existingSecret` or env variable |
| config.credentials.tokenSecret | string | `""` | set token secret, ignored if `BOOKSTACK_TOKEN_SECRET` is defined in `existingSecret` or env variable |
| config.additionalHeaders | object | `{"User-Agent":"bookstack-file-exporter"}` | set any additional headers for http client |
| config.formats | list | `["markdown"]` | set one or more export formats |
| config.keepLast | int | `1` | how many backups to keep on filesystem |
| config.runInterval | int | `0` | setting to `0` uses CronJob resource instead of a deployment |
| config.assets.exportAttachments | bool | `true` | set to export attachments |
| config.assets.exportImages | bool | `true` | set to export images |
| config.assets.exportMeta | bool | `false` | set to export page metadata |
| config.assets.modifyMarkdown | bool | `false` | set to modify asset links for markdown files |
| config.assets.verifySSL | bool | `true` | set to enable SSL verification for all asset requests |
| config.minio.enabled | bool | `false` |  enable minio backup uploads |
| config.minio.accessKey | string | `""` | set minio access key, ignored if `MINIO_ACCESS_KEY` is defined in `existingSecret` or env variable |
| config.minio.secretKey | string | `""` | set minio secret key, ignored if `MINIO_SECRET_KEY` is defined in `existingSecret` or env variable |
| config.minio.bucket | string | `"bookstack-bkps"` | set bucket |
| config.minio.host | string | `"minio.yourdomain.com"` |  |
| config.minio.path | string | `"bookstack/file_backups/"` | set minio path to use |
| config.minio.region | string | `"us-east-1"` | set region |
| config.minio.keepLast | int | `5` | how many backups to keep in minio |
| cron.schedule | string | `"@daily"` | set a valid cron schedule |
| cron.timeZone | string | `""` | set a valid timezone if preferred |
| cron.concurrencyPolicy | string | `"Forbid"` | set the concurrency policy |
| cron.restartPolicy | string | `"OnFailure"` | set restart policy |
| persistence.enabled | bool | `false` | enable persistence using PVC for backup files |
| persistence.existingClaim | string | `""` | set an existingClaim for volume, if set the rest of persistence parameters are ignored |
| persistence.size | string | `"5Gi"` | set the size of the volume |
| persistence.storageClass | string | `""` | set the storage class to use, example: `nfs-provisioner` |
| persistence.mountPath | string | `"/export/dump"` | set the mount path for the volume inside the container |
| persistence.annotations | object | `{}` | set additional annotations for the PVC |
| persistence.accessModes[0] | string | `"ReadWriteOnce"` |  |
| volumeMounts | list | `[]` | set additional volumeMounts |
| volumes | list | `[]` | set additional volumes |

Additional environment variables can be specified in `extraEnv` section.