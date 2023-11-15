# Unpoller
This chart deploys unpoller, an app that gathers metrics from unifi controllers and formats it for prometheus scraping or service monitors.

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

## Upgrade
```
helm upgrade unpoller homeylab/unpoller -n unpoller

# with own values file - recommended
helm upgrade -f my-values.yaml unpoller homeylab/unpoller -n unpoller
```

## Prerequisites
Ensure you have created a user in your unifi site as described here: https://unpoller.com/docs/install/controllerlogin

For a Non UnifiOS Controller (like: https://hub.docker.com/r/linuxserver/unifi-controller), email field will be the 'username'.

## Configuration Options
### Descriptions
The default config options provided in this chart match the same values given in the docker-compose [example](https://unpoller.com/docs/install/dockercompose) from unpoller.

The comments in the provided values.yaml also provide helpful descriptions. Helpful descriptions are shown below for some options:

| Configuration Section | Subsection | Example/Description |
| --------------------- | ---------- | ----------- |
| `existingSecret` |  | Replaces auth sections of `settings.*` with user supplied secret. Secrets should have key/value for env vars. |
| `setttings.unifi.config` | `*` | If scraping multiple controllers, this section uses the `_0_` number, [reference]( https://unpoller.com/docs/install/configuration) - multiple controllers section. Use `extraEnv` section to specify more controllers. |
|  |  `url` | `https://unifi-controller.localdomain:8443` |
|  | `credentials.user` | For a Non UnifiOS Controller (like: [unifi-controller](https://hub.docker.com/r/linuxserver/unifi-controller)), email used for login, will be the `user` |
| `setttings.influxdb.config` | `*` | Send to influxdb, use `setttings.influxdb.enabled` to use this feature. Not enabled by default. |
| `setttings.prometheus` | `*` | Prometheus settings, uncomment `disable` and set to `true` if you want Prometheus disabled. |
| `settings.unpoller` | `*` | additional settings for unpoller |

1. `UP_PROMETHEUS_NAMESPACE`
    * By default, the image is going to use the value of UP_PROMETHEUS_NAMESPACE ( not your actual deployed namespace) to prepend the metrics
    * example: "{{ namespace }}_client_receive_bytes_total" => "unpoller_client_receive_bytes_total"
    * Since the grafana charts (https://github.com/unpoller/dashboards) all have `unpoller` set in the prom queries, you should put this as `unpoller`
    * To clarify: You can install this helm chart in any namespace you'd like though, just keep it the above env variable equal to "unpoller" for metrics
    * This info is still accurate at the time of writing

2. `UP_UNIFI_CONTROLLER_0_USER`
    * As mentioned earlier:
        * For a Non UnifiOS Controller (like: https://hub.docker.com/r/linuxserver/unifi-controller), use the email field as the username.
        * For Cloud Key, should be the actual username

3. `UP_UNIFI_CONTROLLER_0_SAVE_DPI`
    * This is set to `enabled` by default and requires DPI (Deep Packet Inspection) to be enabled for your site in Unifi
    * If not `enabled`, you will see no data

## Upgrade Matrix For Releases
_The matrix below displays certain versions of this helm chart that could result in breaking changes._

| Start Chart Version | Target Chart Version | Upgrade Steps |
| ------------------- | -------------------- | ------------- |
| `1.X.X` | `2.0.0` | Configuration is no longer specified in `config` section as a single key/value object. There is now dedicated sections in the `config` section for each part of unpoller. This allows for easier usability. |

## References
* https://unpoller.com/docs/install/configuration/
* https://unpoller.com/docs/install/dockercompose