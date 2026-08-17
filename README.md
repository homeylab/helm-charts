# Homeylab Helm Charts

Helm charts for apps that either have no existing chart or whose chart has grown stale.

- [Install](#install)
- [OCI registry](#oci-registry)
- [Chart collection](#chart-collection)
- [Recommendations](#recommendations)
- [Tested on](#tested-on)
- [Contributing](#contributing)

## Install

```bash
helm repo add homeylab https://homeylab.github.io/helm-charts/
helm repo update homeylab
helm search repo homeylab
```

## OCI registry

Every chart is also published to an OCI registry, e.g. [unpoller](https://github.com/homeylab/helm-charts/tree/main/charts/unpoller):

```bash
# inspect
helm pull  oci://registry-1.docker.io/homeylabcharts/unpoller --version 2.X.X
helm show all oci://registry-1.docker.io/homeylabcharts/unpoller --version 2.X.X

# render / install / upgrade — add `-f custom-values.yaml` for your own values
helm template unpoller oci://registry-1.docker.io/homeylabcharts/unpoller --version 2.X.X
helm install  unpoller -n <namespace> oci://registry-1.docker.io/homeylabcharts/unpoller --version 2.X.X
helm upgrade  unpoller -n <namespace> oci://registry-1.docker.io/homeylabcharts/unpoller --version 3.X.X
```

## Chart collection

| Application  | Description |
| ------------ | ----------- |
| [unpoller](https://github.com/homeylab/helm-charts/tree/main/charts/unpoller)  | [unpoller](https://github.com/unpoller/unpoller) is a Prometheus exporter that connects to Unifi Controllers and scrapes metrics from your network and devices. |
| [bookstack](https://github.com/homeylab/helm-charts/tree/main/charts/bookstack) | [bookstack](https://github.com/BookStackApp/BookStack) is a self-hosted documentation app, similar to Confluence. Optionally installs mariadb alongside it. |
| [bookstack-file-exporter](https://github.com/homeylab/helm-charts/tree/main/charts/bookstack-file-exporter) | [bookstack-file-exporter](https://github.com/homeylab/bookstack-file-exporter) exports Bookstack pages and their content (_text, images, attachments, metadata_) into a parent-child layout on persistent volumes, optionally pushing to remote object storage. |
| [nut_exporter](https://github.com/homeylab/helm-charts/tree/main/charts/nut-exporter) | **DEPRECATED** — use the first-party chart at [DRuggeri/nut_exporter](https://github.com/DRuggeri/nut_exporter). Prometheus exporter for UPS backup metrics from a NUT server. |
| [exportarr](https://github.com/homeylab/helm-charts/tree/main/charts/exportarr) | [exportarr](https://github.com/onedr0p/exportarr) is a Prometheus exporter for `Arr` applications. Can additionally deploy the [qbittorrent-exporter](https://github.com/homeylab/helm-charts/tree/main/charts/qbittorrent-exporter) and [tdarr-exporter](https://github.com/homeylab/tdarr-exporter) charts. |
| [qbittorrent-exporter](https://github.com/homeylab/helm-charts/tree/main/charts/qbittorrent-exporter) | [qbittorrent-exporter](https://github.com/caseyscarborough/qbittorrent-exporter) is a Prometheus exporter for a qbittorrent instance. |
| [tdarr-exporter](https://github.com/homeylab/helm-charts/tree/main/charts/tdarr-exporter) | [tdarr-exporter](https://github.com/homeylab/tdarr-exporter) is a Prometheus exporter for [Tdarr](https://github.com/HaveAGitGat/Tdarr) — node and worker statistics, including transcode and health-check jobs. |
| [pihole-exporter](https://github.com/homeylab/helm-charts/tree/main/charts/pihole-exporter) | [pihole-exporter](https://github.com/eko/pihole-exporter) is a Prometheus exporter for one or more Pi-hole instances. |
| [v-rising](https://github.com/homeylab/helm-charts/tree/main/charts/v-rising) | A [v-rising dedicated server](https://github.com/TrueOsiris/docker-vrising) for self-hosting the game. |

## Recommendations

**Keep your own values file.** Helm loads the chart's `values.yaml` first, then merges yours on top. Specify only what you override, plus any defaulted value you need to stay constant in case the chart changes — a smaller file is easier to carry across upgrades.

```bash
helm install -f my-values.yaml unpoller homeylab/unpoller -n unpoller --create-namespace
```

**Pin the chart version**, so an upstream chart change can't surprise you:

```bash
helm search repo homeylab/unpoller     # find the version
helm install -f my-values.yaml unpoller homeylab/unpoller -n unpoller --create-namespace --version 1.0.0
```

## Tested on

- k8s `v1.35.5+k3s1`
- Helm `v4.0.5`

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) for the toolchain, chart layout, testing layers and release pipeline. In short: `task verify APP=<chart>` before every commit, and bump the chart `version` or the release is skipped.
