# unpoller — upgrade notes

Every version's upgrade and migration notes for the `unpoller` chart, newest first. The [chart README](https://github.com/homeylab/helm-charts/blob/main/charts/unpoller/README.md)
flags the breaking ones in the **current** major; earlier majors are covered only here.

## From 3.X.X to 4.0.0
This version hardens the chart and standardizes its schema to match the other homeylab exporter charts, and moves `appVersion` to the current upstream image.

- **Image schema standardized (breaking).** `image.name` is removed; `image.repository` (previously the registry host) is now `image.registry`, and the org/name path (previously `image.name`) is now `image.repository`. No image change — still `ghcr.io/unpoller/unpoller`.
- **`helm test` connection-check image schema standardized (breaking).** `testCurlImage.*` is renamed to `tests.image.*` (`registry`/`repository`/`tag`/`pullPolicy`), and the test path moved to `tests.path`.
- **unifi/influxdb auth now renders into a chart-managed Secret (breaking).** `settings.unifi.auth.{user,pass}` and, when `settings.influxdb.enabled`, `settings.influxdb.auth.{user,pass,auth_token}` are no longer emitted as plaintext Deployment env values. They now render into `templates/secret.yaml` and are wired via `envFrom`. `existingSecret` (unchanged field) still takes precedence and must provide the same `UP_*` keys if set.
- **Hardened `securityContext` defaults (potentially breaking).** `runAsNonRoot`, `runAsUser`/`runAsGroup`/`fsGroup: 65532`, `readOnlyRootFilesystem: true`, `drop: [ALL]`. The upstream image has no `USER` directive (defaults to root), but the distroless-static binary runs fine as nonroot; `runAsUser: 65532` must be set explicitly since `runAsNonRoot: true` alone is not sufficient for a root-defaulting image. Override `podSecurityContext`/`securityContext` if you run a customized image.
- **New optional ServiceAccount (`serviceAccount.create`), Ingress (`networking.k8s.io/v1`), and Gateway API `HTTPRoute`** (Ingress/HTTPRoute both disabled by default).
- **New `extraEnvFrom`** — a list of additional `envFrom` sources (`secretRef`/`configMapRef`) merged after the chart-managed or existing Secret, for any extra env you want to inject (see [Targeting Multiple UniFi Controllers](https://github.com/homeylab/helm-charts/blob/main/charts/unpoller/README.md#targeting-multiple-unifi-controllers) for one use).
- **`metrics.prometheusRule` is now implemented.** Previously this values block was a no-op (no template rendered it). `metrics.prometheusRule.enabled: true` now renders a real `PrometheusRule`; the previous cargo-culted example rule (`nut_status`/`UpsStatusUnknown`, copied from an unrelated exporter) has been replaced with a generic `up{job=~".*unpoller.*"} == 0` target-health example.
- **`appVersion` bumped `v3.2.0` -> `v3.3.1`** (current upstream image). The chart's env schema and `/health` endpoint were verified unchanged against the `v3.3.1` image.
