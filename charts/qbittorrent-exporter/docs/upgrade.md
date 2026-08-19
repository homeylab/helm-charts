# qbittorrent-exporter — upgrade notes

Per-version upgrade and migration notes for the `qbittorrent-exporter` chart. The [chart README](https://github.com/homeylab/helm-charts/blob/main/charts/qbittorrent-exporter/README.md)
carries the summary table of which upgrades break; the full steps for each are here.

## From 0.1.X to 1.0.0
First major release. This version **swaps the backing exporter image** and hardens the chart.

- **Backing exporter changed (breaking).** The chart now deploys `martabal/qbittorrent-exporter` (actively maintained, Go) instead of the unmaintained `caseyscarborough/qbittorrent-exporter` (Java, last released 2023). **Metric names and labels differ** — re-import the Grafana dashboard (see below) after upgrading.
- **Values schema changed (breaking).** `settings.config.base_url` and `settings.config.protocol` are removed; set `settings.config.baseUrl` (+ optional `settings.config.timeout`/`fullRefreshInterval`/`insecureSkipVerify`/`minTlsVersion`/`logLevel`). A new `settings.features` block controls metric cardinality (`enableTracker`/`enableHighCardinality`/`enableIncreasedCardinality`/`enableLabelWithTracker`/`enableLabelWithHash`/`enableLabelWithTags`). Auth `settings.auth.user`/`pass`/`apiKey` are unchanged.
- **Credentials render into a chart-managed Secret.** `settings.auth.user`/`pass`/`apiKey` populate `templates/secret.yaml` (keys `QBITTORRENT_USERNAME`/`QBITTORRENT_PASSWORD`/`QBITTORRENT_API_KEY`), wired via `envFrom`. `settings.auth.existingSecret` must now provide those keys.
- **Hardened `securityContext` defaults (breaking).** `runAsNonRoot`, `runAsUser: 65534`, `readOnlyRootFilesystem: true`, `drop: [ALL]`. Fine for the stock image; override if you run a customized one.
- **Image schema standardized (breaking).** `image.registry`/`image.repository`/`image.tag`; the `helm test` connection-check image is `tests.image.registry`/`repository`/`tag`/`pullPolicy` and `tests.path`.
- **Default listen port is now `8090`** (the martabal exporter default), exposed as the `metrics` service port.
- **New optional Ingress (`networking.k8s.io/v1`) and Gateway API `HTTPRoute`** (both disabled by default); **TCP liveness/readiness probes** on the metrics port.
