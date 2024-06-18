# pihole-exporter

![Version: 0.0.1](https://img.shields.io/badge/Version-0.0.1-informational?style=flat-square) ![Type: application](https://img.shields.io/badge/Type-application-informational?style=flat-square) ![AppVersion: v0.4.0](https://img.shields.io/badge/AppVersion-v0.4.0-informational?style=flat-square)

A Helm Chart to deploy a Prometheus [exporter](https://github.com/eko/pihole-exporter) for Pi-hole. Based on `ekofr/pihole-exporter` image.

## Add Chart Repo
```bash
helm repo add homeylab https://homeylab.github.io/helm-charts/
# update the chart, this can also be run to pull new versions of the chart for upgrades
helm repo update homeylab
```

## Install
```bash
helm install pihole-exporter homeylab/pihole-exporter -n pihole-exporter --create-namespace

# with own values file - recommended
helm install -f my-values.yaml pihole-exporter homeylab/pihole-exporter -n pihole-exporter --create-namespace
```

#### OCI Registry Support
```bash
helm install pihole-exporter -n pihole-exporter oci://registry-1.docker.io/homeylabcharts/pihole-exporter --version X.Y.Z --create-namespace

# with own values file - recommended
helm install -f my-values.yaml pihole-exporter -n pihole-exporter oci://registry-1.docker.io/homeylabcharts/pihole-exporter --version X.Y.Z --create-namespace
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
    hostname: pi-hole.example.org
  auth:
    password: "fakepassword"

metrics:
  enabled: true
  serviceMonitor:
    enabled: true
```
</details>
<br>

Install with custom:
```bash
helm install -f custom-values.yaml pihole-exporter homeylab/pihole-exporter -n pihole-exporter --create-namespace
```

## Upgrade
```bash
helm upgrade pihole-exporter homeylab/pihole-exporter -n pihole-exporter

# with own values file - recommended
helm upgrade -f my-values.yaml pihole-exporter homeylab/pihole-exporter -n pihole-exporter
```

#### OCI Registry Support
```bash
helm upgrade pihole-exporter -n pihole-exporter oci://registry-1.docker.io/homeylabcharts/pihole-exporter --version X.Y.Z

# with own values file - recommended
helm upgrade -f my-values.yaml pihole-exporter -n pihole-exporter oci://registry-1.docker.io/homeylabcharts/pihole-exporter --version X.Y.Z
```


## Configuration Options
For a full list of values, see [values.yaml](values.yaml). Some of the most important values are listed below.

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| settings.config.containerPort | int | `9617` | Set the port for metrics scraping |
| settings.config.hostname | string | `"pi-hole.localdomain"` | Set the pihole host or IP address |
| settings.config.port | string | `nil` | Set the pihole port on the pihole host to use, default `80` set by container image |
| settings.config.protocol | string | `""` | Set the pihole host protocol: `http` or `https`, default `http` set by container image |
| settings.auth.existingSecret | string | `""` | use existing secret instead of `auth.password` or `auth.token`. Use variables `PIHOLE_PASSWORD` or `PIHOLE_API_TOKEN` |
| settings.auth.password | string | `""` | Set the pihole password for auth |
| settings.auth.token | string | `""` | Set the pihole token for auth, if token is specified, password will be ignored |
| service.name | string | `"metrics"` | set name for the service |
| service.port | int | `9617` | set port for pihole-exporter scraping, should match the pihole-exporter container port in `settings.config.containerPort` |
| service.protocol | string | `"TCP"` | set protocol for the service |
| service.type | string | `"ClusterIP"` |  |
| extraEnv | object | `{}` | Add extra environment variables |
| metrics.enabled | bool | `true` | enable/disable prometheus podAnnotations and serviceMonitors. |
| metrics.podAnnotations | object | `{"prometheus.io/path":"/metrics","prometheus.io/port":"9617","prometheus.io/scrape":"true"}` | Add podAnnotations for prometheus scraping |
| metrics.podAnnotations."prometheus.io/path" | string | `"/metrics"` | set the path for prometheus scraping |
| metrics.podAnnotations."prometheus.io/port" | string | `"9617"` | set the port for prometheus scraping, should match the service port |
| metrics.serviceMonitor.enabled | bool | `false` | enable/disable serviceMonitor, if enabled podAnnotations will be ignored |
| metrics.serviceMonitor.interval | string | `"1m"` | how often to scrape for serviceMonitor |
| metrics.serviceMonitor.path | string | `"/metrics"` | set the path for prometheus scraping for serviceMonitor |
| metrics.serviceMonitor.scrapeTimeout | string | `"15s"` | scrapeTimeout for serviceMonitor |
| metrics.serviceMonitor.additionalLabels | object | `{}` | set additional labels for serviceMonitor |
| updateStrategy.type | string | `"Recreate"` | set the update strategy for the deployment |

For more customization options, see the upstream image [documentation](https://github.com/eko/pihole-exporter) and use the `extraEnv` to add the options.

## Grafana Dashboards
Official dashboard can be found here from upstream [provider](https://grafana.com/grafana/dashboards/10176-pi-hole-exporter/).

## References
* https://github.com/eko/pihole-exporter