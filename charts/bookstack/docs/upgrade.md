# bookstack — upgrade notes

Per-version upgrade and migration notes for the `bookstack` chart. The [chart README](https://github.com/homeylab/helm-charts/blob/main/charts/bookstack/README.md)
carries the summary table of which upgrades break; the full steps for each are here.

## From 5.3.1 to 5.3.2
**Only if `bookstack-file-exporter.enabled: true` *and* you set `bookstack-file-exporter.persistence.existingClaim`.** The subchart is re-pinned `1.0.2` -> `1.0.3`, which stops rendering the redundant chart-managed PVC it used to provision alongside your existing claim, so `helm upgrade` **deletes that PVC** — and, under the default `Delete` reclaim policy, its PersistentVolume and any data on it. Nothing mounted it, so this is normally the desired cleanup. If you previously ran *without* `existingClaim`, accumulated exports on the chart-managed PVC, and later switched to `existingClaim`, back up or run `kubectl patch pv <pv> -p '{"spec":{"persistentVolumeReclaimPolicy":"Retain"}}'` **before** upgrading. No values keys changed between `1.0.2` and `1.0.3` — see the exporter's [From 1.0.2 to 1.0.3](https://github.com/homeylab/helm-charts/blob/main/charts/bookstack-file-exporter/docs/upgrade.md#from-102-to-103) notes.

## From 5.0.X to 5.1.0
Optional `bookstack-file-exporter` subchart bumped `0.0.2` -> `1.0.0` (breaking config rewrite; API token moved to `bookstack-file-exporter.auth.*`). Only relevant if `bookstack-file-exporter.enabled: true` — follow the [exporter's upgrade notes](https://github.com/homeylab/helm-charts/blob/main/charts/bookstack-file-exporter/docs/upgrade.md#from-0xx-to-100).

## From 4.1.X to 5.0.0
Chart version `5.0.0` is a major, breaking revision. Read every item below that applies to your setup before upgrading.

- **Embedded database chart changed (Bitnami → CloudPirates).** The `mariadb` dependency is now [CloudPirates mariadb](https://github.com/CloudPirates-io/helm-charts/tree/main/charts/mariadb) instead of the (deprecated) Bitnami chart. **Embedded data is NOT migrated automatically** — if you use the embedded database and want to keep your data, back it up and restore it manually (see [Backup And Restore Of MariaDB](https://github.com/homeylab/helm-charts/blob/main/charts/bookstack/README.md#backup-and-restore-of-mariadb) below) before/after upgrading, otherwise the new subchart provisions an empty database.
- **Credentials + APP_KEY now live in a chart-managed Secret** (`templates/secret.yaml`) instead of being passed as plain env values.
- **DB credential wiring.** With the embedded database enabled (`mariadb.enabled: true`), `mariadb.auth.username`/`password`/`database` is the single source of truth — bookstack's DB credentials are derived from it automatically. Set `mariadb.auth.*` only; do **not** also set `config.dbUser`/`config.dbPass`, those only apply when `mariadb.enabled: false` (external database).
- **`existingSecret` combo caveat.** If you set `mariadb.auth.existingSecret`, you must also set the bookstack-side `existingSecret` — the chart cannot read a password out of the mariadb Secret to hand to bookstack.
- **PVC-immutability of DB credentials.** Credentials are fixed at first init of the mariadb data volume (the DB init scripts are skipped once the data directory is non-empty). Changing `mariadb.auth.*` after the PVC already exists does **not** change the stored password and will break the DB connection. To rotate credentials: either run `ALTER USER` inside the database and then update `values.yaml` to match, or re-provision the data volume (data loss).
- **Image field rename.** `image.repository` (previously the registry host) is now `image.registry`; `image.name` is now `image.repository`. Defaults to `lscr.io` / `linuxserver/bookstack`.
- **Test image moved.** `testCurlImage.*` is now `tests.image.*` (`registry`/`repository`/`tag`/`pullPolicy`); `testCurlImage.path` is now `tests.path`.
- **Service port name renamed.** `service.name` is now `service.portName` — it was always naming the Service port, not the Service itself.
- **Ingress defaults changed.** `ingress.annotations` now defaults to `{}` (previously shipped nginx proxy-timeout annotations). If you rely on nginx and didn't set your own annotations, re-add them explicitly. The ingress `apiVersion` is now fixed to `networking.k8s.io/v1`.
- **Optional HTTPRoute.** New `httproute.*` (Gateway API v1) is available as an alternative to ingress. The chart does **not** create the Gateway itself.
- **APP_KEY warning — applies even if you're keeping an external database and its data.** 5.0.0 removes the old fixed default app key. On first upgrade, no chart Secret exists yet, so an empty `config.appKey` will auto-generate a **new** key, which makes previously-encrypted bookstack data (MFA secrets, etc.) undecryptable. **If you have existing data, set `config.appKey` to your current key before upgrading.**
- **GitOps users (ArgoCD/Flux applying via `helm template`).** The lookup-based APP_KEY preservation does not work under template-only rendering — you must pin `config.appKey` explicitly, or the key will regenerate on every sync.

### `linuxserver.enabled` toggle
`linuxserver.PUID`/`PGID`/`UMASK`/`TZ` are s6-overlay/linuxserver.io-image-specific runtime env vars, not generic BookStack config. They're gated behind `linuxserver.enabled` (default `true`, matching the current `lscr.io/linuxserver/bookstack` image) so a future non-linuxserver image can drop them cleanly by setting `linuxserver.enabled: false`. linuxserver images boot as root and use s6 to drop privileges to `PUID`/`PGID` at runtime, so a hardened `securityContext` (`runAsNonRoot: true`, etc.) is only viable once you're on a rootless, non-linuxserver image with `linuxserver.enabled: false` — it is not achievable with the current image.

### Empty embedded DB password is rejected
When `mariadb.enabled: true` and no bookstack-side `existingSecret` is set, leaving `mariadb.auth.password` empty is rejected at render time (`helm template`/`install`/`upgrade` will fail with an explicit error) instead of silently breaking BookStack's DB connection. Leaving it empty would make the embedded MariaDB auto-generate a random password on first boot that BookStack has no way to read, causing a silent authentication failure. Set `mariadb.auth.password` to a real value, or use the `mariadb.auth.existingSecret` + bookstack-side `existingSecret` combo instead.

### Migrating data from 4.x

BookStack has no built-in full export/import — a migration is done via a database dump, a copy of the uploaded files, and carrying over your `APP_KEY` (see the [BookStack backup/restore docs](https://www.bookstackapp.com/docs/admin/backup-restore/)). The 4.x → 5.0.0 change swaps the embedded database chart but does **not** migrate data for you; the steps below move it manually. A logical SQL dump is portable across both the Bitnami→CloudPirates swap and the MariaDB version change.

1. **Dump the old database** — the `bookstack` database only, not the system tables: `mariadb-dump -u root -p bookstack > bookstack.sql`, then `kubectl cp` it out of the old mariadb pod. See [Backup And Restore Of MariaDB](https://github.com/homeylab/helm-charts/blob/main/charts/bookstack/README.md#backup-and-restore-of-mariadb) below for the pod and credential details.
2. **Note your old `APP_KEY`** — in 4.x this was `config.appKey` (the chart's old fixed default if you never changed it). It encrypts MFA secrets and other data; losing it makes that data unrecoverable.
3. **Copy the uploaded files** out of the old bookstack `/config` volume — user-uploaded images, page attachments, and any custom themes (BookStack's instance-specific data; see the backup/restore docs for the exact directories).
4. **Install 5.0.0 fresh** with the embedded CloudPirates MariaDB, and set `config.appKey` to the value from step 2 — do this **before first boot**, or previously-encrypted data (MFA, etc.) becomes unrecoverable.
5. **Restore** — import `bookstack.sql` into the new `bookstack` database, and copy the files from step 3 back into the new `/config` volume.
6. On first boot, BookStack runs its database migrations automatically, upgrading the schema to the new version.

> Do not point the new CloudPirates database at the old Bitnami PVC — credentials are baked in at first init and the physical data dir isn't portable across the swap. Use the logical dump/restore above.

## From 4.0.X to 4.1.0
`fileBackups` has been moved to its own chart and can be enabled by setting `bookstack-file-exporter.enabled` to `true`

## From 3.X.X to 4.0.0
Bookstack version is updated to `v24.10` from `v24.05.2`. The docker image from `linuxserver/bookstack` introduces the requirement for an appKey to be set in the `config` section. This will required to be set by the user, see [here](https://github.com/linuxserver/docker-bookstack?tab=readme-ov-file#parameters) for more information or the chart README's [Configuration Options](https://github.com/homeylab/helm-charts/blob/main/charts/bookstack/README.md#configuration-options) section. `DB_USER` and `DB_PASS` env variables have been changed to `DB_USERNAME` and `DB_PASSWORD` for those that use the `existingSecret` option.

## From 2.8.X to 3.0.0
Optional embedded mariadb chart version updated to `18.0.2` from `14.1.4`; MariaDB itself stays on a `11.3.X` release. If you set additional options under the embedded `mariadb` section of your `values.yaml`, they may need adjusting for that chart's changes — check its upstream upgrade notes first. Superseded for anyone going to `5.0.0` or later, which replaces the Bitnami dependency with CloudPirates outright.

## From 2.4.X to 2.5.0
File exporter has been upgraded to `1.0.0` which has some breaking configuration changes.

## From 2.2.X to 2.3.X
Application URL moved to its own option, `config.appUrl`, instead of being set through `extraEnv` as `APP_URL`.

**This is still live, not just a deprecation.** `templates/deployment.yaml` renders `APP_URL` from `config.appUrl` and then ranges `extraEnv` *after* it, so an `extraEnv.APP_URL` left over from `2.2.X` emits a second `APP_URL` entry that silently wins over `config.appUrl`. Remove it from `extraEnv` and set `config.appUrl`.
