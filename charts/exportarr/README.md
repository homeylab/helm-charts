# exportarr
This chart deploys [exportarr](https://github.com/onedr0p/exportarr), an app that gathers Prometheus metrics from `Arr` instances. See upstream repository for supported applications.

## Add Chart Repo
```
helm repo add homeylab https://homeylab.github.io/helm-charts/
helm repo update homeylab
```

## Install
```
helm install exportarr  homeylab/exportarr -n exportarr --create-namespace

# with own values file - recommended
helm install -f my-values.yaml homeylab/exportarr -n exportarr --create-namespace
```

#### Example
Using a sample `custom-values.yaml` file:
```yaml
# custom-values.yaml
metrics:
  serviceMonitor:
    enabled: true
    additionalLabels:
      app: exportarr
apps:
  radarr:
    enabled: true
    url: "https://radarr.somedomain/"
    apiKey: "" # provide here or `existingSecret` section
  sonarr:
    enabled: true
    url: "https://sonarr.somedomain/"
    apiKey: ""
    extraEnv:
      ENABLE_ADDITIONAL_METRICS: true # example specifying extraEnv
  prowlarr:
    enabled: true
    url: "https://prowlarr.somedomain/"
    apiKey: ""
  bazarr:
    enabled: true
    url: "https://bazarr.somedomain/"
    apiKey: ""
```

Install with custom:
```
helm install -f custom-values.yaml homeylab/exportarr -n exportarr --create-namespace
```

## Upgrade
```
helm upgrade exportarr homeylab/exportarr -n exportarr

# with own values file - recommended
helm upgrade -f my-values.yaml exportarr homeylab/exportarr -n exportarr
```

## Configuration Options
| Configuration Section | Subsection | Example/Description |
| --------------------- | ---------- | ----------- |
| `metrics` | `*` | This section allows users to set configuration for Prometheus `podAnnotations`, `serviceMonitors`, etc. See `values.yaml` section for more details on what can be customized. These sections are applied to all exportarrs.<br><br>**In the future, plan is to provide override sections in each `app.{{ app_name }}` section.** |
| `apps` | `*` | For each supported `Arr` app, provide configuration and properties. Note the `apps` is iterated over (`key` is used as an arg), it is technically possible to add new apps with a new `key` and same `value` structure, as long as exportarr supports it. |
| `apps.{{ app_name }}` | `enabled` | For each supported `Arr` app, choose which are enabled/disabled. For each app that is enabled, an exportarr instance will be deployed. |
| `apps.{{ app_name }}.existingSecret` |  `*` | Provide an existing secret and the `key` within the secret data to use for the `apiKey` of the `{{ app_name }}` instance. If this section is supplied, `apps.{{ app_name }}.apiKey` will be ignored. If auth is not required, do not provide any `existingSecret.secretKey` or `apiKey`.  |
| `apps.{{ app_name }}.extraEnv` |  | Set any additional env variables here for only the `{{ app_name }}` exportarr instance. |
| `extraEnv` |  | Set any additional env variables here for all exportarr instances. All keys will be upper cased and values quoted. |

In addition, `configMap` for configuration files can be supplied to all exportarr instances (via `volumes` and `volumeMounts`) or for only certain ones (via `app.{{ app_name }}.volumes` and `app.{{ app_name }}.volumeMounts`).
