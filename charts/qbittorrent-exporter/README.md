# qbittorrent-exporter
Table of Contents
- [qbittorrent-exporter](#qbittorrent-exporter)
  - [Notice For OCI Changes](#notice-for-oci-changes)
  - [Add Chart Repo](#add-chart-repo)
  - [Install](#install)
  - [Upgrade](#upgrade)
  - [Configuration Options](#configuration-options)
  - [Grafana Dashboards](#grafana-dashboards)

This chart deploys [qbittorrent-exporter](https://github.com/caseyscarborough/qbittorrent-exporter), an app that gathers Prometheus metrics from `qbittorrent` instances.

This chart is also included as an optional deployment in the [exportarr](https://github.com/homeylab/helm-charts/tree/main/charts/exportarr) helm chart. You can use the `exportarr` chart and set `qbittorrent-exporter.enabled` if you prefer having all your `Arr` related exporters in one chart.

## Notice For OCI Changes
**Due to container registries not supporting OCI artifacts and images having the same tag, [reference](https://forums.docker.com/t/tag-overlap-in-oci-artifacts/131453), OCI registry is being moved to `registry-1.docker.io/homeylabcharts`.** This new registry should be used today and moving forward.

**As of `1/17/2024`, OCI artifacts will no longer be pushed to the old OCI registry, `registry-1.docker.io/homeylab`. On `March 2024`, the OCI artifacts in `registry-1.docker.io/homeylab` will be removed and should no longer be referenced.**

Users should not see any issue if they switch, since chart names can remain the same and only the OCI registry url changes. If there is an issue, please feel free to open a Github Issue.

If you do not use OCI artifacts and instead use traditional `helm repo add`, there is no action required.

## Add Chart Repo
```bash
helm repo add homeylab https://homeylab.github.io/helm-charts/
# update the chart, this can also be run to pull new versions of the chart for upgrades
helm repo update homeylab
```

## Install
```bash
helm install qbittorrent-exporter homeylab/qbittorrent-exporter -n qbittorrent-exporter --create-namespace

# with own values file - recommended
helm install -f my-values.yaml qbittorrent-exporter homeylab/qbittorrent-exporter -n qbittorrent-exporter --create-namespace
```

#### OCI Registry Support
```bash
helm install qbittorrent-exporter -n qbittorrent-exporter oci://registry-1.docker.io/homeylabcharts/qbittorrent-exporter --version X.Y.Z --create-namespace

# with own values file - recommended
helm install -f my-values.yaml qbittorrent-exporter -n qbittorrent-exporter oci://registry-1.docker.io/homeylabcharts/qbittorrent-exporter --version X.Y.Z --create-namespace
```

### Install Example
Only some options are shown, view `values.yaml` for an exhaustive list. You can add/change more properties as needed.

Click below to expand for an example of a valid `custom-values.yaml` file. 
<details closed>
<summary>custom-values.yaml</summary>
<br>

```yaml
# custom-values.yaml
metrics:
  serviceMonitor:
    enabled: true
    additionalLabels:
      app: qbittorrent-exporter

## provide settings for exporter
settings:
  ## core configuration
  ## ref: https://github.com/caseyscarborough/qbittorrent-exporter#parameters
  config:
    # examples: `http://somehost:8080`, `https://qbit.somedomain.org`
    base_url: "https://qbit.somedomain.org"
  ## provide auth settings
  ## if no auth fields provided, no auth used
  auth:
    # can optionally provide `QBITTORRENT_USERNAME` and `QBITTORRENT_PASSWORD` in existingSecret
    existingSecret: ""
    # if existingSecret is given, username will be ignored
    username: "someuser"
    # if existingSecret is given, password will be ignored
    password: "samplepassword"
  ## extra env applied to exporter
  extraEnv: {}
```
</details>
<br>

Install with custom:
```bash
helm install -f custom-values.yaml qbittorrent-exporter homeylab/qbittorrent-exporter -n qbittorrent-exporter --create-namespace
```

## Upgrade
```bash
helm upgrade qbittorrent-exporter homeylab/qbittorrent-exporter -n qbittorrent-exporter

# with own values file - recommended
helm upgrade -f my-values.yaml qbittorrent-exporter homeylab/qbittorrent-exporter -n qbittorrent-exporter
```

#### OCI Registry Support
```bash
helm upgrade qbittorrent-exporter -n qbittorrent-exporter oci://registry-1.docker.io/homeylabcharts/qbittorrent-exporter --version X.Y.Z

# with own values file - recommended
helm upgrade -f my-values.yaml qbittorrent-exporter -n qbittorrent-exporter oci://registry-1.docker.io/homeylabcharts/qbittorrent-exporter --version X.Y.Z
```

#### Upgrade Matrix For Releases
_The matrix below displays certain versions of this helm chart that could result in breaking changes._

| Start Chart Version | Target Chart Version | Upgrade Steps |
| ------------------- | -------------------- | ------------- |
| `0.0.1` | `0.1.0` | `settiings.extraEnv` moved to root of `values.yaml`, move your values to `extraEnv` instead. |


## Configuration Options
For a full list of options, see `values.yaml` file.

| Configuration Section | Subsection | Example/Description |
| --------------------- | ---------- | ------------------- |
| `metrics` | `*` | This section allows users to set configuration for Prometheus `podAnnotations`, `serviceMonitors`, etc. See `values.yaml` section for more details on what can be customized. |
| `settings.config.base_url` |  |The qBittorrent base URL, example: `https://qbit.somedomain.org`. Port can also be included in this value, example: `http://localhost:8080`. |
| `settings.auth` | `existingSecret` | Overrides `auth.username` and `auth.password` with user supplied secret. Secrets should have key/value for env vars in the form of `QBITTORRENT_USERNAME: {base_64_encoded username}`. |
|  | `username` | Provide username for qbit instance here if not using `existingSecret`. |
|  | `password` | Provide password for qbit instance here if not using `existingSecret`. |
| `extraEnv` |  | Set any additional env variables here for exporter instance. All keys will be upper cased and values quoted. |

## Grafana Dashboards
- Public
  - [https://grafana.com/grafana/dashboards/15116-qbittorrent-dashboard/](https://grafana.com/grafana/dashboards/15116-qbittorrent-dashboard/)
- From Provider
  - [https://github.com/caseyscarborough/qbittorrent-grafana-dashboard](https://github.com/caseyscarborough/qbittorrent-grafana-dashboard)