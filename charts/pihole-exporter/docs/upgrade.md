# pihole-exporter — upgrade notes

Every version's upgrade and migration notes for the `pihole-exporter` chart, newest first. The [chart README](https://github.com/homeylab/helm-charts/blob/main/charts/pihole-exporter/README.md)
flags the breaking ones in the **current** major; earlier majors are covered only here.

## From 1.X.X to 2.0.0
This release renames the `helm test` values to match the convention used by the other charts in this repo. **If you never overrode `testConnImage.*`, no action is needed** — the defaults are unchanged and the deployed exporter is unaffected.

- **`testConnImage.*` renamed to `tests.image.*` (breaking).** Move any overrides:

  | Old value | New value |
  | --------- | --------- |
  | `testConnImage.registry` | `tests.image.registry` |
  | `testConnImage.repository` | `tests.image.repository` |
  | `testConnImage.tag` | `tests.image.tag` |
  | `testConnImage.pullPolicy` | `tests.image.pullPolicy` |
  | `testConnImage.path` | `tests.path` |

  The old keys are no longer read. Helm does not error on unknown values, so a stale `testConnImage:` block is silently ignored rather than rejected — remove it.
- **New `tests.enabled` (default `true`).** Set it to `false` to skip rendering the `helm test` connection-check Pod when there is no live Pi-hole to reach (for example in CI).
- **`tests.image.pullPolicy` is now honoured.** The value existed before but no template read it, so the Pod fell back to Kubernetes' default pull policy. It is now applied as `imagePullPolicy`.
- **New `metrics.prometheusRule` support (additive).** The block previously configured nothing; see [Configuration Options](https://github.com/homeylab/helm-charts/blob/main/charts/pihole-exporter/README.md#configuration-options).

## From 0.1.X to 1.0.0
First major release. Most changes are transparent if you already set `settings.auth.password`/`token` — review the breaking items below before upgrading.

- **Hardened `securityContext` defaults (breaking — motivates the major bump).** The pod now runs with `runAsNonRoot`, `runAsUser: 65534`, `readOnlyRootFilesystem: true`, and `drop: [ALL]`. Fine for the stock `ekofr/pihole-exporter` image; override `podSecurityContext`/`securityContext` if you run a customized one.
- **Credentials render into a chart-managed Secret (behavior-preserving).** `settings.auth.password`/`token` now populate `templates/secret.yaml`, wired via `envFrom`. The container still receives the same `PIHOLE_PASSWORD`, so no action is needed. `settings.auth.existingSecret` users are unaffected.
- **Image schema standardized (breaking).** The image block moved to `image.registry`/`image.repository`/`image.tag`; the new `registry` field defaults to `docker.io` (no image change). For the post-install test image, `testConnImage.name` was renamed to `testConnImage.repository` and a `testConnImage.registry` field was added — adjust only if you overrode those fields.
- **Ingress collapsed to `networking.k8s.io/v1` (requires Kubernetes 1.19+).** The removed `v1beta1`/`extensions` fallbacks are gone.
- **New optional Gateway API `HTTPRoute`.** Enable with `httproute.enabled` as an alternative to ingress (the chart does not create the Gateway).
