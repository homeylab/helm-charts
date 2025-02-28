# Homeylab Helm Charts
Table of Contents
- [Homeylab Helm Charts](#homeylab-helm-charts)
  - [Add Chart Repo to Use these charts](#add-chart-repo-to-use-these-charts)
  - [Search For Apps and Versions](#search-for-apps-and-versions)
  - [OCI Support](#oci-support)
  - [Chart Collection](#chart-collection)
  - [Recommendations](#recommendations)
  - [Tested On](#tested-on)

## Add Chart Repo to Use these charts
```
helm repo add homeylab https://homeylab.github.io/helm-charts/
helm repo update homeylab
```

## Search For Apps and Versions
```
helm search repo homeylab
```

## OCI Support
An OCI supported registry is available for all charts, example using [unpoller](https://github.com/homeylab/helm-charts/tree/main/charts/unpoller) chart.

<details closed>
<summary>Click to Show Example Commands</summary>
<br>

```bash
# pulls chart files locally for you to inspect
helm pull oci://registry-1.docker.io/homeylabcharts/unpoller --version 2.X.X

# outputs all the chart files as stdout
helm show all oci://registry-1.docker.io/homeylabcharts/unpoller --version 2.X.X

# outputs manifests as if an install was being made
# - optionally can use your own values file:  `-f custom-values.yaml`
helm template unpoller oci://registry-1.docker.io/homeylabcharts/unpoller --version 2.X.X

# install chart into your namespace
# - optionally can use your own values file:  `-f custom-values.yaml`
helm install unpoller -n <namespace> oci://registry-1.docker.io/homeylabcharts/unpoller --version 2.X.X

# upgrade existing chart in your namespace
# - optionally can use your own values file:  `-f custom-values.yaml`
helm upgrade unpoller -n <namespace> oci://registry-1.docker.io/homeylabcharts/unpoller --version 3.X.X
```
</details>
<br>

## Chart Collection
A collection of helm charts that I created for some apps that either do not have an existing chart or the chart has grown stale.

For customizations, it is recommended to use your own values file and specify it when using helm with the `-f` flag. See Recommendations section below for more details.

Apps available
| Application  | Description | 
| ------------ | ----------- |
| [unpoller](https://github.com/homeylab/helm-charts/tree/main/charts/unpoller)  | [unpoller](https://github.com/unpoller/unpoller) is a Prometheus exporter that connects to an Unifi Controller(s) and scrapes metrics from your network and devices. |
| [bookstack](https://github.com/homeylab/helm-charts/tree/main/charts/bookstack) | [bookstack](https://github.com/BookStackApp/BookStack) is an app for self and/or collaborated documentation similar to confluence. This chart includes an option to install mariadb alongside it. |
| [bookstack-file-exporter](https://github.com/homeylab/helm-charts/tree/main/charts/bookstack-file-exporter) | [bookstack-file-exporter](https://github.com/homeylab/bookstack-file-exporter) is an exporter that provides a way to export [Bookstack](https://github.com/BookStackApp/BookStack) pages and their content (_text, images, attachments, metadata, etc._) into a relational parent-child layout onto persistent volumes with an option to push to remote object storage locations. |
| [nut_exporter](https://github.com/homeylab/helm-charts/tree/main/charts/nut-exporter) | [nut_exporter](https://github.com/DRuggeri/nut_exporter) is a Prometheus exporter that connects to a NUT server(s) and scrapes UPS backup metrics. |
| [exportarr](https://github.com/homeylab/helm-charts/tree/main/charts/exportarr) | [exportarr](https://github.com/onedr0p/exportarr) is a Prometheus exporter that connects to `Arr` applications and scrapes metrics. This chart has an option to additionally deploy [qbittorrent-exporter](https://github.com/homeylab/helm-charts/tree/main/charts/qbittorrent-exporter) and [tdarr-exporter](https://github.com/homeylab/tdarr-exporter) charts.|
| [qbittorrent-exporter](https://github.com/homeylab/helm-charts/tree/main/charts/qbittorrent-exporter) | [qbittorrent-exporter](https://github.com/caseyscarborough/qbittorrent-exporter) is a Prometheus exporter that connects to a qbittorrent instance and scrapes metrics.  |
| [tdarr-exporter](https://github.com/homeylab/helm-charts/tree/main/charts/tdarr-exporter) | [tdarr-exporter](https://github.com/homeylab/tdarr-exporter) is a Prometheus exporter that connects to a [Tdarr](https://github.com/HaveAGitGat/Tdarr) instance and scrapes general statistics for nodes and their running worker processes including transcode and health check jobs. |
| [pihole-exporter](https://github.com/homeylab/helm-charts/tree/main/charts/pihole-exporter) | [pihole-exporter](https://github.com/eko/pihole-exporter) is a Prometheus exporter that connects to one or more Pi-hole instances and scrapes metrics. |
| [v-rising](https://github.com/homeylab/helm-charts/tree/main/charts/v-rising) | A v-rising dedicated [server](https://github.com/TrueOsiris/docker-vrising) that allows a user host their own server for the game v-rising. |


## Recommendations
### Create A Values File
Use a values file to make changes and save your custom configuration. When using upstream helm charts and specifying your own values file, variables are handled like so:

- First the base default values.yaml in the project/bundle is evaluated and all variables and values loaded.
- When you specify your own file, your configuration is applied on top and overrides (or merges depending on value type) existing configuration loaded from the base values.yaml.

General recommendation is only specify in your own values file what you are customizing or overriding. You may also include variables that are defaulted to a specific value that you need to stay constant, just in case the upstream helm chart changes. This allows you to keep your files minimal and easy to upgrade when values change since your scope is smaller.

Use the `-f` flag like so, example
```
helm install -f my-values.yaml unpoller homeylab/unpoller -n unpoller --create-namespace
```

### Use Versioning
Use chart versioning when installing/upgrading charts. This can help prevent unexpected changes/issues from occuring if the upstream chart has been updated in a breaking manner. Example
```
# Get version to install
helm search repo homeylab/unpoller
NAME             	CHART VERSION	APP VERSION	DESCRIPTION
homeylab/unpoller	1.0.0        	2.8.1      	A Helm chart for Kubernetes

# Install a specific version
helm install -f my-values.yaml unpoller homeylab/unpoller -n unpoller --create-namespace --version 1.0.0
```

## Tested On
All charts are currently tested on:
- k8s `v1.29.4+k3s1`
- Helm `v3.15.1`

### Chart Testing
**WIP Section**

To contribute, there are a many ways to do testing and many are valid. I am using Dev Containers extension from VScode to set up a consistent environment across my devices.

To use the same Dev Containers, ensure you have the extension enabled and add a copy of your kubectl config in `.devcontainer/`. Name it `kube_config` and it will be ignored by git (in .gitignore) and will be used during Dev Container build.

The provided makefile can then be used for testing via helm and [chart-testing](https://github.com/helm/chart-testing).

Example:
```
# Use `app=` for targeting a chart
# below runs chart-testing for the specified chart/app
make test app=bookstack
```