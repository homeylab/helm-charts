
# tdarr-exporter
Table of Contents
- [tdarr-exporter](#tdarr-exporter)
  - [Add Chart Repo](#add-chart-repo)
  - [Install](#install)
  - [Upgrade](#upgrade)
  - [Configuration Options](#configuration-options)
  - [Grafana Dashboards](#grafana-dashboards)

This chart deploys [tdarr-exporter](https://github.com/homeylab/tdarr-exporter), an app that gathers Prometheus metrics from `Tdarr` instances.

## Add Chart Repo
```bash
helm repo add homeylab https://homeylab.github.io/helm-charts/
# update the chart, this can also be run to pull new versions of the chart for upgrades
helm repo update homeylab
```

## Install
```bash
helm install tdarr-exporter homeylab/tdarr-exporter -n tdarr-exporter --create-namespace

# with own values file - recommended
helm install -f my-values.yaml tdarr-exporter homeylab/tdarr-exporter -n tdarr-exporter --create-namespace
```

#### OCI Registry Support
```bash
helm install tdarr-exporter -n tdarr-exporter oci://registry-1.docker.io/homeylab/tdarr-exporter --version X.Y.Z --create-namespace

# with own values file - recommended
helm install -f my-values.yaml tdarr-exporter -n tdarr-exporter oci://registry-1.docker.io/homeylab/tdarr-exporter --version X.Y.Z --create-namespace
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
      app: tdarr-exporter

## define settings for the exporter
settings:
  ## tdarr connection settings
  config:
    # `url` - This is a required property and must be provided.
    # If no protocol is provided (http/https), defaults to using https. 
    # Examples: `tdarr.example.com`, `http://tdarr.example.com`
    url: "somedomain.com"
    # `verify_ssl` - This is an optional property and defaults to `true`.
    # If set to `false`, the exporter will not verify the SSL certificate of the tdarr instance.
    verify_ssl: true
    log_level: "info"
  ## if you change these, ensure you change `service` and `metrics.*` sections
  ## Generally you should not need to change below
  prometheus:
    port: "9090"
    path: "/metrics"
```
</details>
<br>

Install with custom:
```bash
helm install -f custom-values.yaml tdarr-exporter homeylab/tdarr-exporter -n tdarr-exporter --create-namespace
```

## Upgrade
```bash
helm upgrade tdarr-exporter homeylab/tdarr-exporter -n tdarr-exporter

# with own values file - recommended
helm upgrade -f my-values.yaml tdarr-exporter homeylab/tdarr-exporter -n tdarr-exporter
```

#### OCI Registry Support
```bash
helm upgrade tdarr-exporter -n tdarr-exporter oci://registry-1.docker.io/homeylab/tdarr-exporter --version X.Y.Z

# with own values file - recommended
helm upgrade -f my-values.yaml tdarr-exporter -n tdarr-exporter oci://registry-1.docker.io/homeylab/tdarr-exporter --version X.Y.Z
```

### Upgrade Matrix For Releases
_The matrix below displays certain versions of this helm chart that could result in breaking changes._

## Configuration Options
For a full list of options, see `values.yaml` file.

| Configuration Section | Default                                                                                               | Example/Description |
| --------------------- | ----------------------------------------------------------------------------------------------------- | ------------------- |
| `metrics` | By default `podAnnotations` are enabled. Set `serviceMonitor.enabled` to `true` to instead use `serviceMonitors`. | This section allows users to set configuration for Prometheus `podAnnotations`, `serviceMonitors`, etc. See `values.yaml` section for more details on what can be customized. |
| `settings.config.url` | `NONE`                                                                                                | This is a required property and must be provided. If no protocol is provided (`http/https`), defaults to using `https`. Examples: `tdarr.example.com`, `http://tdarr.example.com`. |
| `settings.config.verify_ssl` | `true`                                                                                         | If set to `false`, the exporter will not verify the SSL certificate of the tdarr instance. |
| `settings.config.log_level` | `info`                                                                                          | Log level to use: `debug`, `info`, `warn`, `error`. |

Additional environment variables can be specified in `extraEnv` section.

## Grafana Dashboards
- From Provider
  - [https://github.com/homeylab/tdarr-exporter/tree/main/examples](https://github.com/homeylab/tdarr-exporter/tree/main/examples)