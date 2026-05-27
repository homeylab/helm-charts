# nut-exporter

> [!WARNING]
> **DEPRECATED.** This chart is superseded by the first-party chart maintained by the
> `nut_exporter` author and will receive no further updates. Please migrate to the
> upstream chart: **https://github.com/DRuggeri/nut_exporter** (`charts/nut-exporter`).
>
> The upstream chart is a superset of this one — it tracks newer `appVersion`s and adds
> Ingress and a Grafana dashboard ConfigMap. Existing installs keep working, but no new
> versions will be released here.

## Migration to the upstream chart

Switching repos requires rewriting your values file — the value keys differ. Mapping:

| This chart (homeylab) | Upstream (DRuggeri) | Notes |
| --------------------- | ------------------- | ----- |
| `image.repository: docker.io` + `image.name: druggeri/nut_exporter` | `image.repository: ghcr.io/druggeri/nut_exporter` | Same binary, different registry. |
| `settings.config.*` | `settings.config.*` | Carried over; confirm key names against upstream `values.yaml`. |
| `settings.auth.nut_exporter_username` / `_password` | `settings.auth.*` / `existingSecret` | Confirm against upstream `values.yaml`. |
| `existingSecret` | `existingSecret` | Same intent. |
| `webconfig_file` | `webconfig_file` | Same intent. |
| `metrics.serviceMonitor.*` | `metrics.serviceMonitor.*` | Same intent. |
| (not available) | `ingress.*` | New upstream feature. |
| (not available) | dashboard ConfigMap | New upstream feature. |

> [!NOTE]
> This chart's post-install `helm test` connection check has no upstream equivalent.
> Always diff your values against the upstream `values.yaml` before migrating — verify
> every key rather than assuming a 1:1 match.

Table of Contents
- [nut-exporter](#nut-exporter)
  - [Add Chart Repo](#add-chart-repo)
  - [Install](#install)
  - [Upgrade](#upgrade)
  - [Configuration Options](#configuration-options)
  - [Grafana Dashboards](#grafana-dashboards)

This chart provides [nut_exporter](https://github.com/DRuggeri/nut_exporter) [image](https://hub.docker.com/r/druggeri/nut_exporter) from `DRuggeri` repository. 

## Add Chart Repo
```bash
helm repo add homeylab https://homeylab.github.io/helm-charts/
# update the chart, this can also be run to pull new versions of the chart for upgrades
helm repo update homeylab
```

## Install
```bash
helm install nut-exporter  homeylab/nut-exporter -n nut-exporter --create-namespace

# with own values file - recommended
helm install -f my-values.yaml nut-exporter homeylab/nut-exporter -n nut-exporter --create-namespace
```

#### OCI Registry Support
```bash
helm install nut-exporter -n nut-exporter oci://registry-1.docker.io/homeylabcharts/nut-exporter --version X.Y.Z --create-namespace

# with own values file - recommended
helm install -f my-values.yaml nut-exporter -n nut-exporter oci://registry-1.docker.io/homeylabcharts/nut-exporter --version X.Y.Z --create-namespace
```

### Install Example
Only some options are shown, view `values.yaml` for an exhaustive list. You can add/change more properties as needed.

Click below to expand for an example of a valid `custom-values.yaml` file. 
<details closed>
<summary>custom-values.yaml</summary>
<br>

```yaml
# custom-values.yaml
settings:
  config:
    nut_exporter_server: "10.0.100.1"
    nut_exporter_serverport: 3493
  # ignored if `existingSecret specified`
  auth:
    nut_exporter_username: "user"
    nut_exporter_password: "samplepass"
metrics:
  enabled: true
  serviceMonitor:
    enabled: true
    additionalLabels:
      app: nut_exporter
    relabelings: # assign target nut_exporter `ups: primary` label in Prometheus
      - targetLabel: ups
        replacement: primary
```
</details>
<br>

Install with custom:
```bash
helm install -f custom-values.yaml nut-exporter homeylab/nut-exporter -n nut-exporter --create-namespace
```

## Upgrade
```bash
helm upgrade nut-exporter homeylab/nut-exporter -n nut-exporter

# with own values file - recommended
helm upgrade -f my-values.yaml nut-exporter homeylab/nut-exporter -n nut-exporter
```

#### OCI Registry Support
```bash
helm upgrade nut-exporter -n nut-exporter oci://registry-1.docker.io/homeylabcharts/nut-exporter --version X.Y.Z

# with own values file - recommended
helm upgrade -f my-values.yaml nut-exporter -n nut-exporter oci://registry-1.docker.io/homeylabcharts/nut-exporter --version X.Y.Z
```

## Configuration Options
For a full list of options, see `values.yaml` file.

| Configuration Section | Subsection | Example/Description |
| --------------------- | ---------- | ------------------- |
| `metrics` | `*` | This section allows users to set configuration for Prometheus `podAnnotations`, `serviceMonitors`, etc. See `values.yaml` section for more details on what can be customized. |
| `existingSecret` |  | Replaces auth sections of `settings.*.auth` with user supplied secret. Secrets should have key/value for env vars. |
| `setttings.config` | `*` | Provide any runtime env variables as described in [usage flags](https://github.com/DRuggeri/nut_exporter#usage). All keys will be upper cased and values quoted. You can add additional vars as needed.<br><br>Examples:<br> `nut_exporter_server: 10.0.100.1`<br>`nut_exporter_serverport: 3493` |
| `settings.auth` |  `*` | This entire section is ignored if `existingSecret` is supplied.<br><br>Similar to `settings.config`, these are runtime env variables, specifically for auth in this case. You can add additional auth vars as needed |
|  | `nut_exporter_username` | If NUT server requires auth, provide username here. |
|  | `nut_exporter_password` | If NUT server requires auth, provide password here. |
| `extraRunFlags` |  | If you prefer to add configuration via [run flags](https://github.com/DRuggeri/nut_exporter#usage), this section can be used to provide args in the `--log.level=debug` syntax.<br>This is also useful for flags that do not have an env variable available |
| `extraEnv` |  | Set any additional env variables here. All keys will be upper cased and values quoted |
| `webconfig_file` |  |  Specify optional [web-configuration](https://github.com/prometheus/exporter-toolkit/blob/master/docs/web-configuration.md) file.<br>Use inline syntax as shown in the commented section in `values.yaml`. If specified, an `extraRunFlags` will be added automatically as `--web.config.file` |

To set the `ups` label for Prometheus metrics, use the following fields in `metrics.serviceMonitor` section, example:

```yaml
metrics:
  serviceMonitor:
    relabelings:
    - targetLabel: ups #label key
      replacement: primary #value
```

### Scraping Multiple NUT Servers
For setting up metrics for multiple UPS servers from a single instance, follow upstream [documentation](https://github.com/DRuggeri/nut_exporter#example-prometheus-scrape-configurations) on using multiple `scrape_configs` targets in Prometheus.

Example:
```yaml
- job_name: nut-primary
    metrics_path: /ups_metrics
    static_configs:
      - targets: ['nut-exporter.nut-exporter:9199'] # service for exporter, example given from chart defaults
        labels:
          ups:  "primary"
    params:
      ups: [ "primary" ]
      server: [ "nutserver1" ]
  - job_name: nut-secondary
    metrics_path: /ups_metrics
    static_configs:
      - targets: ['nut-exporter.nut-exporter:9199'] # service for exporter, example given from chart defaults
        labels:
          ups:  "secondary"
    params:
      ups: [ "secondary" ]
      server: [ "nutserver2" ]
```

## Grafana Dashboards
- Public
  - [https://grafana.com/grafana/dashboards/19308-prometheus-nut-exporter-for-druggeri/](https://grafana.com/grafana/dashboards/19308-prometheus-nut-exporter-for-druggeri/)
- From Provider
  - [https://github.com/DRuggeri/nut_exporter/blob/master/dashboard/dashboard.json](https://github.com/DRuggeri/nut_exporter/blob/master/dashboard/dashboard.json)