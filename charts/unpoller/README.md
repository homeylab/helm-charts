# Unpoller
This chart deploys [unpoller](https://unpoller.com/docs), an app that gathers metrics from unifi controllers and formats it for Prometheus.

*Note: You should set some chart values by creating your own values.yaml and save that locally*

## Add Chart Repo
```
helm repo add homeylab https://homeylab.github.io/helm-charts/
helm repo update homeylab
```

## Install
```
helm install unpoller homeylab/unpoller -n unpoller --create-namespace

# with own values file - recommended
helm install -f my-values.yaml homeylab/unpoller -n unpoller --create-namespace
```

#### Example
Click below to expand for an example of a valid `custom-values.yaml` file. You can add/change more properties as needed.

<details open>
<summary>custom-values.yaml</summary>
<br>

```yaml
# custom-values.yaml
settings:
  unifi:
    config:
      url: "https://unifi-controller.somedomain:8443"
      save_sites: true
      save_ids: true
      save_events: true
      save_alarms: true
      save_anomalies: true
      save_dpi: true
      verify_ssl: false
    auth:
      user: "user@somedomain"
      pass: "somepass"
  influxdb:
    enabled: false
  ## additional configuration for prometheus can be specified in `extraEnv`
  prometheus:
    namespace: "unpoller"
    http_listen: "0.0.0.0:9130"
metrics:
  ## if serviceMonitor enabled, pod annotations will be ignored
  serviceMonitor:
    enabled: true
    additionalLabels:
      app: unpoller
```
</details>
<br>

Install with custom:
```
helm install -f custom-values.yaml homeylab/unpoller -n unpoller --create-namespace
```

## Upgrade
```
helm upgrade unpoller homeylab/unpoller -n unpoller

# with own values file - recommended
helm upgrade -f my-values.yaml unpoller homeylab/unpoller -n unpoller
```

## Prerequisites
Ensure you have created a user in your unifi site as described here: https://unpoller.com/docs/install/controllerlogin

For a Non UnifiOS Controller (like: [unifi-controller](https://hub.docker.com/r/linuxserver/unifi-controller)), email used for login will be the `user` used for authentication.

## Configuration Options
### Descriptions
The default config options provided in this chart match the same values given in the docker-compose [example](https://unpoller.com/docs/install/dockercompose) from unpoller.

Comments in the provided `values.yaml` provide helpful descriptions. Some of the same information is also shown below for a few key options:

| Configuration Section | Subsection | Example/Description |
| --------------------- | ---------- | ------------------- |
| `metrics` | `*` | This section allows users to set configuration for Prometheus `podAnnotations`, `serviceMonitors`, etc. See `values.yaml` section for more details on what can be customized. |
| `existingSecret` |  | Replaces auth sections of `settings.*.auth` with user supplied secret. Secrets should have key/value for env vars. |
| `setttings.unifi.config` | `*` | Unifi connection configuration section.<br><br>If scraping multiple controllers, this section uses the `_0_` number, [reference]( https://unpoller.com/docs/install/configuration) - multiple controllers section. Use `extraEnv` section to specify more controllers. |
|  |  `url` | `https://unifi-controller.localdomain:8443` |
| `settings.unifi.auth` | `*` | This section will be ignored if `existingSecret` is supplied. Provide username/password here. |
|  | `user` | For a Non UnifiOS Controller (like: [unifi-controller](https://hub.docker.com/r/linuxserver/unifi-controller)), email used for login, will be the `user` |
|  | `pass` | Provide the password for the metrics user. |
| `setttings.influxdb.config` | `*` | Send to influxdb, use `setttings.influxdb.enabled` to use this feature. Not enabled by default. |
| `setttings.prometheus` | `*` | Prometheus settings, uncomment `disable` and set to `true` if you want Prometheus disabled. |
| `setttings.prometheus` | `namespace` | By default unpoller is going to use the value of `UP_PROMETHEUS_NAMESPACE` value (this setting) and not your actual deployed namespace to prefix the metrics with a string. Since the grafana [charts](https://github.com/unpoller/dashboards) all have `unpoller_` prefix set in the prom queries, you should put this as `unpoller`. _Note: You can install this helm chart in any namespace you'd like, just set this variable to `unpoller` to work with the existing dashboards without changes._ |
| `settings.unpoller` | `*` | Additional settings for unpoller. |

For additional configuration use the `extraEnv` section.

## Upgrade Matrix For Releases
_The matrix below displays certain versions of this helm chart that could result in breaking changes._

| Start Chart Version | Target Chart Version | Upgrade Steps |
| ------------------- | -------------------- | ------------- |
| `1.X.X` | `2.0.0` | Configuration is no longer specified in `config` section as a single key/value object. There is now dedicated sections in the `config` section for each part of unpoller. This allows for easier usability. |

## Grafana Dashboards
Official dashboards can be imported via json [here](https://github.com/unpoller/dashboards).

## References
* https://unpoller.com/docs/install/configuration/
* https://unpoller.com/docs/install/dockercompose