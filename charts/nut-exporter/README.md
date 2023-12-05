# nut-exporter
This chart provides (nut_exporter)[https://github.com/DRuggeri/nut_exporter] (docker) image[https://hub.docker.com/r/druggeri/nut_exporter] from `DRuggeri` repository. 

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
| `settings.auth.*` |  `*` | This section is ignored if `existingSecret` is supplied.<br>Similar to `settings.config`, these are runtime env variables, specifically for auth in this case. You can add additional auth vars as needed |
| `extraRunFlags` |  | If you prefer to add configuration via [run flags](https://github.com/DRuggeri/nut_exporter#usage), this section can be used to provide args in the `--log.level=debug` syntax.<br>This is also useful for flags that do not have an env variable available |
| `extraEnv` |  | Set any additional env variables here. All keys will be upper cased and values quoted |
| `webconfig_file` |  |  Specify optional [web-configuration](https://github.com/prometheus/exporter-toolkit/blob/master/docs/web-configuration.md) file.<br>Use inline syntax as shown in the commented section in `values.yaml`. If specified, an `extraRunFlags` will be added automatically as `--web.config.file` |

For additional configuration use the `extraEnv` section.

### Scraping Multiple NUT Servers
For setting up metrics for multiple UPS servers from a single instance, follow upstream [documentation](https://github.com/DRuggeri/nut_exporter#example-prometheus-scrape-configurations) on using multiple `scrape_configs` targets in Prometheus.
