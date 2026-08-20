# v-rising — upgrade notes

Every version's upgrade and migration notes for the `v-rising` chart, newest first. The [chart README](https://github.com/homeylab/helm-charts/blob/main/charts/v-rising/README.md)
flags the breaking ones in the **current** major; earlier majors are covered only here.

## From 0.X.X to 1.0.0
This version graduates the chart to `1.0.0` and standardizes its schema to match the other homeylab charts.

- **Image schema standardized (breaking).** `image.repository` (previously `registry/repo` combined, e.g. `trueosiris/vrising`) is unchanged, but a new `image.registry` field (default `docker.io`) is now prepended to build the image reference. If you previously overrode `image.repository` with a full `registry/repo` path, split it into `image.registry` + `image.repository`.
- **rcon Service renamed (breaking, only if `service.rcon.enabled: true`).** The RCON `Service` previously shared the same name as the main game Service, which made `helm install`/`upgrade` fail as soon as both were enabled together (a real bug, not a supported configuration). It's now named `<fullname>-rcon`. If you had `service.rcon.enabled: true` and something depends on the old Service name (e.g. a firewall rule or DNS record), update it to the new `-rcon`-suffixed name.
- **Ingress removed (breaking, only if you had `ingress.enabled: true`).** The `Ingress` template was already broken (it referenced a nonexistent `service.port` value) and could not have worked for a UDP game server regardless. It and the `ingress:` values block are removed. Expose the server via the `service.server` `LoadBalancer`/`NodePort` Service instead — see [Exposing the Server (UDP)](https://github.com/homeylab/helm-charts/blob/main/charts/v-rising/README.md#exposing-the-server-udp).
- **Deployment update strategy is now `Recreate`.** The pod holds its steam/world PVCs as `ReadWriteOnce`, so the default `RollingUpdate` (which briefly runs a second pod) deadlocks on volume multi-attach during an upgrade. `Recreate` terminates the old pod first for a clean handoff. Override via `updateStrategy` if your storage supports `ReadWriteMany`.
- **Empty `config` values are no longer rendered as env vars.** Previously, an unset `config.branch` rendered `BRANCH=""` into the container env. It's now omitted entirely when empty, letting the image apply its own default. This does not change the effective behavior for the stock `branch: ""` default.
