# tdarr-exporter — upgrade notes

Per-version upgrade and migration notes for the `tdarr-exporter` chart. The [chart README](https://github.com/homeylab/helm-charts/blob/main/charts/tdarr-exporter/README.md)
carries the summary table of which upgrades break; the full steps for each are here.

## From 1.X.X to 2.0.0
This version hardens the chart and standardizes its schema to match the other homeylab exporter charts, and moves `appVersion` to the current upstream image. The image repository is unchanged (still `homeylab/tdarr-exporter`).

- **Image schema standardized (breaking).** `image.name` is renamed to `image.repository`; the previous `image.repository` (the registry host) is now `image.registry`. No image change — still `docker.io/homeylab/tdarr-exporter`.
- **`helm test` connection-check image schema standardized (breaking).** `testCurlImage.*` is renamed to `tests.image.*` (`registry`/`repository`/`tag`/`pullPolicy`), and the test path moved to `tests.path`.
- **Hardened `securityContext` defaults (breaking).** `runAsNonRoot`, `runAsUser`/`runAsGroup`/`fsGroup: 65532`, `readOnlyRootFilesystem: true`, `drop: [ALL]`. The image runs as a distroless nonroot user (UID/GID 65532), so this is fine for the stock image; override `podSecurityContext`/`securityContext` if you run a customized one.
- **Inline API key now renders into a chart-managed Secret (behavior-preserving).** `settings.config.apiKey` populates `templates/secret.yaml` (key `TDARR_API_KEY`), wired via `secretKeyRef`. The container still receives the same `TDARR_API_KEY`, so no action is needed. `settings.config.existingSecret` is unchanged and still takes precedence.
- **New optional Ingress (`networking.k8s.io/v1`) and Gateway API `HTTPRoute`** (both disabled by default).
- **`appVersion` bumped `2.1.0` -> `3.0.0`** (current `homeylab/tdarr-exporter` image). The chart's env schema, `/healthz` probes, and exported metric names were verified unchanged against the `3.0.0` image. Review the [upstream v3.0.0 release notes](https://github.com/homeylab/tdarr-exporter/releases/tag/v3.0.0) for any behavior changes before upgrading.

## From 1.1.X to 1.2.0
Exporter upgraded to upstream `v2.x` (`appVersion` `1.4.3` -> `2.1.0`). No chart configuration changes. This is a breaking _upstream_ release: it requires Tdarr `v2.24.01`+ and renames/removes many Prometheus metrics and labels, so existing dashboards and alerts will break. Review the [upstream v2.0.0 release notes](https://github.com/homeylab/tdarr-exporter/releases/tag/v2.0.0) and reimport the [Grafana dashboard](https://grafana.com/grafana/dashboards/20388-tdarr/) before upgrading.
