# qbittorrent-exporter
This chart deploys [qbittorrent-exporter](https://github.com/caseyscarborough/qbittorrent-exporter), an app that gathers Prometheus metrics from `qbittorrent` instances.

## Add Chart Repo
```
helm repo add homeylab https://homeylab.github.io/helm-charts/
helm repo update homeylab
```

## Install
```
helm install qbittorrent-exporter  homeylab/qbittorrent-exporter -n qbittorrent-exporter --create-namespace

# with own values file - recommended
helm install -f my-values.yaml homeylab/qbittorrent-exporter -n qbittorrent-exporter --create-namespace
```

#### Example
Click below to expand for an example of a valid `custom-values.yaml` file. You can add/change more properties as needed.

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
```
helm install -f custom-values.yaml homeylab/qbittorrent-exporter -n qbittorrent-exporter --create-namespace
```

## Upgrade
```
helm upgrade qbittorrent-exporter homeylab/qbittorrent-exporter -n qbittorrent-exporter

# with own values file - recommended
helm upgrade -f my-values.yaml qbittorrent-exporter homeylab/qbittorrent-exporter -n qbittorrent-exporter
```

## Configuration Options
| Configuration Section | Subsection | Example/Description |
| --------------------- | ---------- | ------------------- |
| `metrics` | `*` | This section allows users to set configuration for Prometheus `podAnnotations`, `serviceMonitors`, etc. See `values.yaml` section for more details on what can be customized. |
| `settings.config.base_url` |  |The qBittorrent base URL, example: `https://qbit.somedomain.org`. Port can also be included in this value, example: `http://localhost:8080`. |
| `settings.auth` | `existingSecret` | Overrides `auth.username` and `auth.password` with user supplied secret. Secrets should have key/value for env vars in the form of `QBITTORRENT_USERNAME: {base_64_encoded username}`. |
|  | `username` | Provide username for qbit instance here if not using `existingSecret`. |
|  | `password` | Provide password for qbit instance here if not using `existingSecret`. |
| `settings.extraEnv` |  | Set any additional env variables here for exporter instance. All keys will be upper cased and values quoted. |

## Grafana Dashboards
- Public
  - [https://grafana.com/grafana/dashboards/15116-qbittorrent-dashboard/](https://grafana.com/grafana/dashboards/15116-qbittorrent-dashboard/)
- From Provider
  - [https://github.com/caseyscarborough/qbittorrent-grafana-dashboard](https://github.com/caseyscarborough/qbittorrent-grafana-dashboard)