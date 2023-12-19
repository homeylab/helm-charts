# exportarr
This chart deploys [exportarr](https://github.com/onedr0p/exportarr), an app that gathers Prometheus metrics from `Arr` instances. See upstream repository for supported applications.

This chart can optionally install a Prometheus exporter for `qbittorrent` using a separate helm [chart](https://github.com/homeylab/helm-charts/tree/main/charts/qbittorrent-exporter), allowing users to consolidate different exporters into a single helm chart. See [Additional Exporters](#additional-exporters) section for more information.

## Add Chart Repo
```bash
helm repo add homeylab https://homeylab.github.io/helm-charts/
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
helm install exportarr -n exportarr oci://registry-1.docker.io/homeylab/exportarr --version X.Y.Z --create-namespace

# with own values file - recommended
helm install -f my-values.yaml exportarr -n exportarr oci://registry-1.docker.io/homeylab/exportarr --version X.Y.Z --create-namespace
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
      enabled: true
      url: "https://radarr.somedomain/"
      apiKey: "someApiKey" # provide here or `existingSecret` section
    sonarr:
      enabled: true
      url: "https://sonarr.somedomain/"
      apiKey: "someApiKey"
      extraEnv:
        ENABLE_ADDITIONAL_METRICS: true # example specifying extraEnv
    prowlarr:
      enabled: true
      url: "https://prowlarr.somedomain/"
      apiKey: "someApiKey"
    bazarr:
      enabled: true
      url: "https://bazarr.somedomain/"
      apiKey: "someApiKey"

## additional exporters ##
qbittorrent-exporter:
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
helm upgrade exportarr -n exportarr oci://registry-1.docker.io/homeylab/exportarr --version X.Y.Z

# with own values file - recommended
helm upgrade -f my-values.yaml exportarr -n exportarr oci://registry-1.docker.io/homeylab/exportarr --version X.Y.Z
```


## Configuration Options
Below are some key options explained for this helm chart. For an exhaustive list, look at `values.yaml` file.

### Exportarr
| Property                                       | Example/Description                                                                                                                          | Value   |
| ---------------------------------------------- | -------------------------------------------------------------------------------------------------------------------------------------------- | ------- |
| `exportarr.metrics.enabled`                    | Toggle metric scraping for Prometheus. If set to `false`, pods are still deployed but without `podAnnotations` or `serviceMonitors`.         | `true`  |
| `exportarr.metrics.podAnnotations`             | Set/override `podAnnotations` for Prometheus.                                                                                                | `{}`    |
| `exportarr.metrics.serviceMonitor`             | Set/override `serviceMonitor` configuration for Prometheus                                                                                   | `{}`    |
| `exportarr.apps`                               | For each supported `Arr` app, provide configuration and properties. Each `key` in `apps` is iterated over, allowing you to define more apps. | `{}`    |
| `exportarr.apps.{{ app_name }}.enabled`        | For each supported `Arr` app, choose which are enabled/disabled.                                                                             | `false` |
| `exportarr.apps.{{ app_name }}.url`            | Required field from exportarr. Provide an `url` to reach the `{{ app_name }}` instance.                                                      | `""`    |
| `exportarr.apps.{{ app_name }}.existingSecret` | Provide an existing secret and the `key` within the secret data to use for the `apiKey` of the `{{ app_name }}` instance.                    | `{}`    |
| `exportarr.apps.{{ app_name }}.apiKey`         | If `existingSecret` is not supplied, provide `apiKey` for `{{ app_name }}` instance directly. If no auth required, leave blank.              | `""`    |
| `exportarr.apps.{{ app_name }}.extraEnv`       | Set any additional env variables here for only the `{{ app_name }}` exportarr instance.                                                      | `{}`    | 
| `exportarr.apps.{{ app_name }}.volumes`        | Set `volumes` to use for `{{ app_name }}` exportarr instance like `configMaps` or `secrets`.                                                 | `{}`    |
| `exportarr.apps.{{ app_name }}.volumeMounts`   | Set `volumeMounts` for your `volumes for `{{ app_name }}` exportarr instance.                                                                | `{}`    |
| `exportarr.extraEnv`                           | Set any additional env variables here for all exportarr instances. All keys will be upper cased and values quoted.                           | `{}`    |
| `exportarr.volumes`                            | Set `volumes` to use for all exportarr instance like `configMaps` or `secrets`.                                                              | `{}`    |
| `exportarr.volumeMounts`                       | Set `volumeMounts` for your `volumes` for all exportarr instance.                                                                            | `{}`    |
| `qbittorrent-exporter.enabled`                 | Setting this value to `true` deploys an additional exporter for `qbittorrent`. See [Additional Exporter](#qbittorrent) for more details.     | `false` |


## Additional Exporters
#### qbittorrent
Enable additional exporter for `qbittorrent-exporter` by setting `qbittorrent-exporter.enabled` to `true.`
```
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
    extraEnv: {}
```

More options and details are available from upstream helm [chart](https://github.com/homeylab/helm-charts/tree/main/charts/qbittorrent-exporter).
