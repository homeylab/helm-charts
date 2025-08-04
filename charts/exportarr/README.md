# exportarr
Table of Contents
- [exportarr](#exportarr)
  - [Add Chart Repo](#add-chart-repo)
  - [Install](#install)
  - [Upgrade](#upgrade)
  - [Configuration Options](#configuration-options)
  - [Additional Exporters](#additional-exporters)

This chart deploys [exportarr](https://github.com/onedr0p/exportarr), an app that gathers Prometheus metrics from `Arr` instances. See upstream repository for supported applications.

This chart can optionally install a Prometheus exporter for the following:

1. `qbittorrent` using a separate helm [chart](https://github.com/homeylab/helm-charts/tree/main/charts/qbittorrent-exporter)
2. `Tdarr` using a separate helm [chart](https://github.com/homeylab/helm-charts/tree/main/charts/tdarr-exporter)
 
This allows users to consolidate different `Arr` related exporters into a single helm chart. See [Additional Exporters](#additional-exporters) section for more information.

## Add Chart Repo
```bash
helm repo add homeylab https://homeylab.github.io/helm-charts/
# update the chart, this can also be run to pull new versions of the chart for upgrades
helm repo update homeylab
```

## Install
```bash
helm install exportarr  homeylab/exportarr -n exportarr --create-namespace

# with own values file - recommended
helm install -f my-values.yaml exportarr homeylab/exportarr -n exportarr --create-namespace
```

#### OCI Registry Support
```bash
helm install exportarr -n exportarr oci://registry-1.docker.io/homeylabcharts/exportarr --version X.Y.Z --create-namespace

# with own values file - recommended
helm install -f my-values.yaml exportarr -n exportarr oci://registry-1.docker.io/homeylabcharts/exportarr --version X.Y.Z --create-namespace
```

### Install Example
Only some options are shown, view `values.yaml` for an exhaustive list. You can add/change more properties as needed.

Click below to expand for an example of a valid `custom-values.yaml` file. 
<details closed>
<summary>custom-values.yaml</summary>
<br>

```yaml
# custom-values.yaml
exportarr:
  metrics:
    serviceMonitor:
      enabled: true
      additionalLabels:
        app: exportarr
  apps:
    radarr:
    - name: main
      enabled: true
      url: "https://radarr.somedomain/"
      apiKey: "someApiKey" # provide here or `existingSecret` section
    sonarr:
    - name: main
      enabled: true
      url: "https://sonarr.somedomain/"
      apiKey: "someApiKey"
      extraEnv:
        ENABLE_ADDITIONAL_METRICS: true # example specifying extraEnv
    prowlarr:
    - name: main
      enabled: true
      url: "https://prowlarr.somedomain/"
      apiKey: "someApiKey"
    bazarr:
    - name: main
      enabled: true
      url: "https://bazarr.somedomain/"
      apiKey: "someApiKey"

## additional exporters ##
qbittorrent-exporter:
  enabled: false

tdarr-exporter:
  enabled: false
```
</details>
<br>

Install with custom:
```bash
helm install -f custom-values.yaml exportarr homeylab/exportarr -n exportarr --create-namespace
```

## Upgrade
```bash
helm upgrade exportarr homeylab/exportarr -n exportarr

# with own values file - recommended
helm upgrade -f my-values.yaml exportarr homeylab/exportarr -n exportarr
```

#### OCI Registry Support
```bash
helm upgrade exportarr -n exportarr oci://registry-1.docker.io/homeylabcharts/exportarr --version X.Y.Z

# with own values file - recommended
helm upgrade -f my-values.yaml exportarr -n exportarr oci://registry-1.docker.io/homeylabcharts/exportarr --version X.Y.Z
```

#### Upgrade Matrix For Releases
_The matrix below displays certain versions of this helm chart that could result in breaking changes._

| Start Chart Version | Target Chart Version | Upgrade Steps |
| ------------------- | -------------------- | ------------- |
| `1.X.X` | `2.0.0` | This version is a breaking change.<br><br>The data structure under `exportarr.apps.{{ radarr/sonarr/etc }}` have been changed to an array instead of object type. This flexibility allows you to list numerous instances of each *arr application (i.e. `radarr1`, `radarr2`, `sonarr1`, and so on), allowing you to consolidate multiple chart installations and configurations into one.<br><br>In addition, `exportarr.testCurlImage` has been renamed to `exportarr.testImage` |

## Configuration Options
Below are some key options explained for this helm chart. For an exhaustive list, look at `values.yaml` file.

### Exportarr
| Property                                       | Example/Description                                                                                                                          | Value   |
| ---------------------------------------------- | -------------------------------------------------------------------------------------------------------------------------------------------- | ------- |
| `exportarr.metrics.enabled`                    | Toggle metric scraping for Prometheus. If set to `false`, pods are still deployed but without `podAnnotations` or `serviceMonitors`.         | `true`  |
| `exportarr.metrics.podAnnotations`             | Set/override `podAnnotations` for Prometheus.                                                                                                | `{}`    |
| `exportarr.metrics.serviceMonitor`             | Set/override `serviceMonitor` configuration for Prometheus                                                                                   | `{}`    |
| `exportarr.apps`                               | For each supported `Arr` app, provide configuration and properties. Each `key` in `apps` is iterated over, allowing you to define more apps as needed even if the chart is not updated. | `{}`    |
| `exportarr.apps.{{ app_name }}[0].enabled`        | For each `Arr` app instance, choose which are enabled/disabled.                                                                              | `false` |
| `exportarr.apps.{{ app_name }}[0].name   `        | Select the name of the `Arr` app instance. This name will be used in container naming.                                                       | `false` |
| `exportarr.apps.{{ app_name }}[0].url`            | Required field from exportarr. Provide an `url` to reach the `{{ app_name }}` instance.                                                      | `""`    |
| `exportarr.apps.{{ app_name }}[0].existingSecret` | Provide an existing secret and the `key` within the secret data to use for the `apiKey` of the `{{ app_name }}` instance.                    | `{}`    |
| `exportarr.apps.{{ app_name }}[0].apiKey`         | If `existingSecret` is not supplied, provide `apiKey` for `{{ app_name }}` instance directly. If no auth required, leave blank.              | `""`    |
| `exportarr.apps.{{ app_name }}[0].extraEnv`       | Set any additional env variables here for only the `{{ app_name }}` exportarr instance.                                                      | `{}`    | 
| `exportarr.apps.{{ app_name }}[0].volumes`        | Set `volumes` to use for `{{ app_name }}` exportarr instance like `configMaps` or `secrets`.                                                 | `{}`    |
| `exportarr.apps.{{ app_name }}[0].volumeMounts`   | Set `volumeMounts` for your `volumes for `{{ app_name }}` exportarr instance.                                                                | `{}`    |
| `exportarr.apps.{{ app_name }}[0].metrics     `   | Override `exportarr.metrics` properties for an `{{ app_name }}` exportarr instance.                                                          | `{}`    |
| `exportarr.extraEnv`                           | Set any additional env variables here for all exportarr instances. All keys will be upper cased and values quoted.                           | `{}`    |
| `exportarr.volumes`                            | Set `volumes` to use for all exportarr instance like `configMaps` or `secrets`.                                                              | `{}`    |
| `exportarr.volumeMounts`                       | Set `volumeMounts` for your `volumes` for all exportarr instance.                                                                            | `{}`    |
| `qbittorrent-exporter.enabled`                 | Setting this value to `true` deploys an additional exporter for `qbittorrent`. See [Additional Exporter](#qbittorrent) for more details.     | `false` |
| `tdarr-exporter.enabled`                       | Setting this value to `true` deploys an additional exporter for `tdarr-exporter`. See [Additional Exporter](#Tdarr) for more details.        | `false` |

## Additional Exporters
#### qbittorrent
Enable additional exporter for `qbittorrent-exporter` by setting `qbittorrent-exporter.enabled` to `true`.
```yaml
qbittorrent-exporter:
  # enable/disable
  enabled: true
  # more options available than shown
  metrics:
    serviceMonitor:
      enabled: false
  settings:
    config:
      base_url: ""
    auth:
      existingSecret: ""
      username: ""
      password: ""
  # extra env applied to exporter
  extraEnv: {}
```

More options and details are available from upstream helm [chart](https://github.com/homeylab/helm-charts/tree/main/charts/qbittorrent-exporter).

#### Tdarr
Enable additional exporter for `tdarr-exporter` by setting `tdarr-exporter.enabled` to `true`.

```yaml
tdarr-exporter:
  enabled: false
  metrics:
    serviceMonitor:
      enabled: false
  settings:
    # more options available than shown
    config:
      # If no protocol is provided (http/https), defaults to using https. 
      # Examples: `tdarr.example.com`, `http://tdarr.example.com`
      url: ""
      # If set to `false`, the exporter will not verify the SSL certificate of the tdarr instance.
      verify_ssl: true
      log_level: "info"
  # extra env applied to exporter
  extraEnv: {}
```

More options and details are available from upstream helm [chart](https://github.com/homeylab/helm-charts/tree/main/charts/tdarr-exporter).