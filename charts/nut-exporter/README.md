# nut-exporter
This chart provides [nut_exporter](https://github.com/DRuggeri/nut_exporter) [image](https://hub.docker.com/r/druggeri/nut_exporter) from `DRuggeri` repository. 

## Add Chart Repo
```
helm repo add homeylab https://homeylab.github.io/helm-charts/
helm repo update homeylab
```

## Install
```
helm install nut-exporter  homeylab/nut-exporter -n nut-exporter  --create-namespace

# with own values file - recommended
helm install -f my-values.yaml homeylab/nut-exporter  -n nut-exporter  --create-namespace
```

## Upgrade
```
helm upgrade nut-exporter homeylab/nut-exporter -n nut-exporter

# with own values file - recommended
helm upgrade -f my-values.yaml nut-exporter homeylab/nut-exporter -n nut-exporter
```

## Configuration Options
| Configuration Section | Subsection | Example/Description |
| --------------------- | ---------- | ----------- |
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
```
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