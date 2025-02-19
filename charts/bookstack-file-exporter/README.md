# bookstack-file-exporter

![Version: 0.0.1](https://img.shields.io/badge/Version-0.0.1-informational?style=flat-square) ![Type: application](https://img.shields.io/badge/Type-application-informational?style=flat-square) ![AppVersion: 1.4.0](https://img.shields.io/badge/AppVersion-1.4.0-informational?style=flat-square)

A Helm chart for Kubernetes

## Values

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| config.additionalHeaders | object | `{"User-Agent":"bookstack-file-exporter"}` | set any additional headers for http client |
| config.assets.exportAttachments | bool | `true` | set to export attachments |
| config.assets.exportImages | bool | `true` | set to export images |
| config.assets.exportMeta | bool | `false` | set to export page metadata |
| config.assets.modifyMarkdown | bool | `false` | set to modify asset links for markdown files |
| config.assets.verifySSL | bool | `true` | set to enable SSL verification |
| config.credentials.tokenId | string | `""` | set token id, ignored if `BOOKSTACK_TOKEN_ID` is defined via secret or env variable |
| config.credentials.tokenSecret | string | `""` | set token secret, ignored if `BOOKSTACK_TOKEN_SECRET` is defined via secret or env variable |
| config.formats | list | `["markdown"]` | set one or more export formats |
| config.host | string | `"http://bookstack.bookstack.svc.cluster.local"` | set the bookstack instance URL |
| config.keepLast | int | `1` | how many backups to keep on filesystem |
| config.minio.accessKey | string | `""` | set minio access key, ignored if `MINIO_ACCESS_KEY` is defined via secret or env variable |
| config.minio.bucket | string | `"bookstack-bkps"` | set bucket |
| config.minio.enabled | bool | `true` |  |
| config.minio.host | string | `"minio.yourdomain.com"` |  |
| config.minio.keepLast | int | `5` | how many backups to keep |
| config.minio.path | string | `"bookstack/file_backups/"` | set minio path to use |
| config.minio.region | string | `"us-east-1"` | set region |
| config.minio.secretKey | string | `""` | set minio secret key, ignored if `MINIO_SECRET_KEY` is defined via secret or env variable |
| config.runInterval | int | `0` | setting to `0` uses CronJob resource instead of a deployment |
| cron.concurrencyPolicy | string | `"Forbid"` | set the concurrency policy |
| cron.restartPolicy | string | `"OnFailure"` | set restart policy |
| cron.schedule | string | `"@daily"` | set a valid cron schedule |
| cron.timeZone | string | `""` | set a valid timezone if preferred |
| existingSecret | string | `""` | use an existing secret for credentials |
| extraEnv | object | `{}` | set extra environment variables |
| persistence.accessModes | []string | `"ReadWriteOnce"` |  |
| persistence.annotations | object | `{}` | set additional annotations for the PVC |
| persistence.enabled | bool | `true` | enable persistence using PVC for backup files if using `runMode: application` |
| persistence.existingClaim | string | `""` | set an existingClaim for volume, if set the rest of persistence parameters are ignored |
| persistence.mountPath | string | `"/export/dump"` | set the mount path for the volume inside the container |
| persistence.size | string | `"10Gi"` | set the size of the volume |
| persistence.storageClass | string | `""` | set the storage class to use, example: `nfs-provisioner` |
| volumeMounts | list | `[]` | set additional volumeMounts |
| volumes | list | `[]` | set additional volumes |

