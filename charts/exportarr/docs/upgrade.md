# exportarr — upgrade notes

Per-version upgrade and migration notes for the `exportarr` chart. The [chart README](https://github.com/homeylab/helm-charts/blob/main/charts/exportarr/README.md)
carries the summary table of which upgrades break; the full steps for each are here.

## From 3.1.X to 4.0.0
This release standardizes the image schema and the `helm test` values to match the other charts in this repo, and implements the previously-inert `prometheusRule` block. Only the value renames are breaking — if you never overrode the image or test-image values, the defaults are unchanged and no action is needed.

- **`exportarr.image` schema renamed (breaking).** The old block stored the registry in `repository` and the image path in `name`; both are renamed to the standard scheme. Move any overrides:

  | Old | New |
  | --- | --- |
  | `exportarr.image.repository` (held the registry, e.g. `ghcr.io`) | `exportarr.image.registry` |
  | `exportarr.image.name` (held the repository, e.g. `onedr0p/exportarr`) | `exportarr.image.repository` |

- **`exportarr.testImage.*` moved to `exportarr.tests.image.*` (breaking).** Move any overrides:

  | Old | New |
  | --- | --- |
  | `exportarr.testImage.repository` | `exportarr.tests.image.registry` |
  | `exportarr.testImage.name` | `exportarr.tests.image.repository` |
  | `exportarr.testImage.tag` | `exportarr.tests.image.tag` |
  | `exportarr.testImage.pullPolicy` | `exportarr.tests.image.pullPolicy` |
  | `exportarr.testImage.path` | `exportarr.tests.path` |

  The old `testImage:` keys are no longer read. Helm does not reject unknown values, so a stale block is silently ignored rather than erroring — remove it.
- **PrometheusRule now implemented (additive).** `exportarr.metrics.prometheusRule` (`enabled`/`labels`/`rules`) previously rendered nothing; it now renders a single umbrella-wide `PrometheusRule`. Default `enabled: false` — no change unless you opt in.
- **`exportarr.tests.enabled` added (additive).** Toggles the `helm test` connection-check Pod (default `true`). `exportarr.tests.image.pullPolicy` is now honoured (it was previously ignored, so the Pod fell back to Kubernetes' default pull policy).
- **`exportarr.podLabels` added (additive).** Optional labels applied to all exportarr pods (default `{}`).
- **Optional subcharts bumped (only if enabled).** `qbittorrent-exporter` `1.0.1` -> `1.1.0` and `tdarr-exporter` `2.0.1` -> `2.1.0`, both adding their own PrometheusRule support. See the [qbittorrent-exporter](https://github.com/homeylab/helm-charts/tree/main/charts/qbittorrent-exporter) and [tdarr-exporter](https://github.com/homeylab/helm-charts/tree/main/charts/tdarr-exporter) READMEs.

## From 3.0.X to 3.1.0
Optional `tdarr-exporter` subchart bumped `1.2.0` -> `2.0.0` (hardened `securityContext`, standardized image schema, `appVersion` -> upstream `v3.0.0`); passthrough value keys are unchanged. **Only affects installs with `tdarr-exporter.enabled`** — see the subchart's [upgrade notes](https://github.com/homeylab/helm-charts/blob/main/charts/tdarr-exporter/docs/upgrade.md#from-1xx-to-200) notes.

## From 2.1.X to 3.0.0
Backing `qbittorrent-exporter` subchart swapped image/schema, hardened `securityContext` on all exportarr instances, inline `apiKey` now renders into a chart-managed Secret.

This version hardens the umbrella chart and swaps the backing image for the optional `qbittorrent-exporter` subchart.

- **`qbittorrent-exporter` subchart swapped (breaking, only if enabled).** The optional `qbittorrent-exporter` dependency bumped `0.1.0` -> `1.0.0`, moving from the unmaintained `caseyscarborough/qbittorrent-exporter` (Java) to the actively maintained `martabal/qbittorrent-exporter` (Go). Its values schema changed (keys renamed, new options) — see the subchart's own [upgrade notes](https://github.com/homeylab/helm-charts/blob/main/charts/qbittorrent-exporter/docs/upgrade.md#from-01x-to-100) notes, which apply verbatim under this chart's top-level `qbittorrent-exporter:` key. **Metric names and labels differ** — re-import its Grafana dashboard after upgrading.
- **Hardened `securityContext` defaults (breaking).** All `exportarr` instances now run with `runAsNonRoot`, `runAsUser: 65532` (distroless nonroot), `readOnlyRootFilesystem: true`, and `drop: [ALL]`. Fine for the stock `onedr0p/exportarr` image; override `exportarr.podSecurityContext`/`exportarr.securityContext` if you run a customized one.
- **Credentials render into a chart-managed Secret (behavior-preserving).** Inline `exportarr.apps.<app>[].apiKey` now populates a chart-managed per-instance `Secret`, referenced via `secretKeyRef`, instead of being set as a plaintext environment variable. No action needed — `existingSecret` still takes precedence over `apiKey` as before.

## From 1.X.X to 2.0.0
`exportarr.apps.<app>` (radarr/sonarr/etc.) changed from an object to a list, allowing multiple instances of the same `Arr` app (e.g. `radarr1`, `radarr2`). `exportarr.testCurlImage` was renamed to `exportarr.testImage`.
