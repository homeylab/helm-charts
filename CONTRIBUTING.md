# Contributing

A monorepo of independent Helm charts under `charts/<chart>/`, each wrapping one upstream app or Prometheus exporter. This guide covers the toolchain, the layout of a chart, and the path from edit to release.

## Table of Contents

- [Prerequisites](#prerequisites)
- [Tasks](#tasks)
- [Anatomy of a chart](#anatomy-of-a-chart)
- [Testing layers](#testing-layers)
- [Contribution workflow](#contribution-workflow)
- [Commit and PR conventions](#commit-and-pr-conventions)
- [Continuous integration](#continuous-integration)
- [Versioning and release](#versioning-and-release)
- [Gotchas](#gotchas)

## Prerequisites

| Tool | Purpose | Install |
| --- | --- | --- |
| [Helm](https://helm.sh/docs/intro/install/) 3 | render/lint/package charts | `helm` |
| [go-task](https://taskfile.dev/installation/) | task runner (all commands below) | `task` |
| [helm-unittest](https://github.com/helm-unittest/helm-unittest) | template unit tests | `helm plugin install https://github.com/helm-unittest/helm-unittest` |
| [helm-docs](https://github.com/norwoodj/helm-docs) | generate `README.md` from templates | `go install github.com/norwoodj/helm-docs/cmd/helm-docs@latest` |
| [kubeconform](https://github.com/yannh/kubeconform) | validate rendered manifests | `kubeconform` |
| [chart-testing](https://github.com/helm/chart-testing) (`ct`) | install charts on a real cluster | `ct` |
| [kind](https://kind.sigs.k8s.io/) + `kubectl` | local cluster for `ct` / `deploy-local` | `kind`, `kubectl` |
| [actionlint](https://github.com/rhysd/actionlint) (+ [shellcheck](https://www.shellcheck.net/)) | lint the GitHub Actions workflows | `actionlint`, `shellcheck` |

A [`.devcontainer`](.devcontainer/) that builds a chart-testing image with the whole toolchain is provided if you prefer a container. Its Dockerfile copies `.devcontainer/kube_config` (gitignored) to `~/.kube/config` at build time — drop a copy of your kubectl config there first.

Every task takes the target chart as `APP=<chart>`, e.g. `task verify APP=bookstack`. Run `task --list` to see all targets.

## Tasks

[`Taskfile.yml`](Taskfile.yml) wraps every tool above behind one `APP=`-scoped interface, so you never memorize raw flags.

### Validate — cluster-free, run before every commit

| Task | Runs |
| --- | --- |
| `task lint APP=<chart>` | `helm lint` |
| `task kubeconform APP=<chart>` | `scripts/ci/kubeconform.sh` — rendered manifests against k8s + CRD schemas (k8s `1.30.0`, override with `K8S_VERSION=`) |
| `task unittest APP=<chart>` | `helm unittest` |
| **`task verify APP=<chart>`** | **`lint` + `kubeconform` + `unittest`** — the local mirror of the cluster-free CI gate. Run before every commit. |
| `task template APP=<chart>` | `helm template … --debug` |
| `task docs APP=<chart>` | regenerate `README.md` via helm-docs |
| `task actionlint` | `actionlint` over `.github/workflows/` — repo-wide, no `APP=` |

### Local cluster

| Task | Runs |
| --- | --- |
| `task test APP=<chart>` | `ct install` against `ci/*-values.yaml` (kind) |
| `task local-template APP=<chart>` | render with your `.local/values/<chart>.yaml` |
| `task dryrun-local APP=<chart>` | `helm upgrade --install --dry-run=client` with local values |
| `task deploy-local APP=<chart>` | install/upgrade with local values into namespace `local-<chart>` |
| `task clean-local APP=<chart>` | delete the local release and its namespace |

> **`deploy-local`/`dryrun-local` use your *current* kube-context** and your credentialed, gitignored `.local/values/<chart>.yaml`. Check `kubectl config current-context` first and `task clean-local` after.

`task test` needs a running cluster. Create it against a dedicated kubeconfig — an unqualified `kind create cluster` merges into `~/.kube/config` and repoints your current context away from a real cluster:

```bash
export KUBECONFIG=/tmp/kind-ct.kubeconfig
kind create cluster --name ct-test --kubeconfig "$KUBECONFIG"
task test APP=<chart>
kind delete cluster --name ct-test      # also drops its kubeconfig entries
unset KUBECONFIG
```

Heavy charts (`bookstack`, `v-rising`) need a few minutes to reach Ready — add `--helm-extra-args "--timeout 600s"` if you invoke `ct` directly.

### Package / release — mostly CI, available locally

| Task | Runs |
| --- | --- |
| `task update-dep APP=<chart>` | `helm dependency update` |
| `task pkg APP=<chart>` / `pkg-with-dep APP=<chart>` | `helm package` (with `-u` to bundle deps) |
| `task oci-push FILE=<chart>.tgz` | `helm push` to the OCI registry |

## Anatomy of a chart

```
charts/<chart>/
├── Chart.yaml              # version = CHART version (SemVer, gates releases);
│                           # appVersion = upstream image tag. A `# renovate:` comment
│                           # above appVersion binds it to a Docker datasource.
├── values.yaml             # defaults; the `# --` comments become the README value table
├── values.schema.json      # (optional) values validation
├── README.md.gotmpl        # helm-docs source → generated README.md (never edit README.md)
├── README.md               # GENERATED — do not hand-edit
├── docs/upgrade.md         # per-version upgrade notes; helmignored, README links it by URL
├── templates/
│   ├── *.yaml              # manifests
│   ├── _helpers.tpl        # named templates (labels, names, …)
│   ├── NOTES.txt           # post-install notes
│   └── tests/              # `helm test` connection probes (live-cluster smoke check,
│                           #  distinct from the unit tests below)
├── tests/*_test.yaml       # helm-unittest suites (+ tests/__snapshot__/)
└── ci/*-values.yaml        # one file per `ct install` scenario (must be self-contained)
```

Most charts wrap a single upstream image. The exceptions are the two umbrellas: `bookstack` (`mariadb` + `bookstack-file-exporter`) and `exportarr` (`qbittorrent-exporter` + `tdarr-exporter`).

## Testing layers

Four independent layers, cheapest first. Lower layers for logic, upper layers to prove it runs.

| Layer | Tool / command | Cluster? | What it proves |
| --- | --- | --- | --- |
| **Unit** | `task unittest APP=<chart>` (`tests/*_test.yaml`) | No | Templates render the right output for given values — Secret keys, env wiring, conditionals, which manifests appear. Best place for `existingSecret` and edge-case paths. |
| **Static** | `task lint` + `task kubeconform APP=<chart>` | No | Chart is well-formed and rendered manifests are schema-valid, CRD kinds included. Catches what unittest can't: wrong field names and wrong types. |
| **Integration** | `task test APP=<chart>` (`ct install`) | Yes (kind) | Chart installs and becomes Ready for each `ci/*-values.yaml` scenario, and runs the `helm test` hooks at the end. |
| **Live behavior** | `task deploy-local APP=<chart>` → inspect → `task clean-local` | Yes (your context) | Real backend connectivity, env-var semantics, probes under load — using your credentialed local values. |

**`task verify`** bundles the two cluster-free layers and is the pre-commit gate.

### `helm test` (connection probes)

Most charts ship `templates/tests/test-connection.yaml` — a Pod annotated `helm.sh/hook: test` that curls the service and expects a 200. It runs against a live release, so `ct install` exercises it automatically; you rarely invoke `helm test <release> -n <namespace>` by hand outside a `deploy-local` debug session. (`bookstack-file-exporter` and `v-rising` ship no probe — neither serves HTTP.)

**Exception: probes that can't pass without a live backend.** Some exporters serve an error until they can scrape upstream, so the probe can never go green in an empty `ct install` namespace. Those charts gate the hook behind `tests.enabled` (default `true`) and set it `false` in `ci/*-values.yaml`, leaving `ct install` to verify readiness only. `qbittorrent-exporter` is the current case: it serves 503 on `/metrics` until it reaches a live qBittorrent, and redirects other paths there. Prefer a backend-independent probe where upstream offers one (`tdarr-exporter` keeps its probe because `/healthz` is independent of `config.url`); reach for the gate only when it doesn't.

## Contribution workflow

1. **Branch** off `main`, with an issue/ticket number if there is one.
2. **Change** `charts/<chart>/`; update the `# --` comments if you touched `values.yaml`.
3. **Regenerate docs** if `values.yaml`, `Chart.yaml` or `README.md.gotmpl` changed: `task docs APP=<chart>`.
4. **Bump the chart `version`** in `Chart.yaml` — without it the release is silently skipped.
5. **Run the gate**: `task verify APP=<chart>`.
6. **Optionally** `task test APP=<chart>` (kind) and/or `task deploy-local APP=<chart>` for behavior the static gate can't prove. Clean up after.
7. **Open a PR** against `main`. CI blocks merge until it passes.

## Commit and PR conventions

- **Commits** follow [Conventional Commits](https://www.conventionalcommits.org/): `feat` (MINOR), `fix` (PATCH), plus `refactor`, `chore`, `ci`, `docs`, `test`. Append `!` for breaking changes (`feat(pihole-exporter)!: …`). Scope to a single chart where possible.
- **PR descriptions** state what changed (facts), why, and a test plan — the `task verify` result, any live-test output. Call out breaking changes explicitly.

## Continuous integration

Three workflows run on a PR to `main`.

**[`ci.yml`](.github/workflows/ci.yml)** — `ct` over each chart changed vs `main`, so the gate scales with your diff. [`.github/ct/ct.yaml`](.github/ct/ct.yaml) is the source of truth, mirrored locally by `task verify`.

1. **`ct lint`** — `helm lint` + yamllint + yamale schema + **`--check-version-increment`**, which fails unless `Chart.yaml` `version` exceeds `main`'s.
2. **`helm unittest` + `kubeconform`** via `additional-commands`.
3. **`ct install`** on kind, waiting for Ready (`nut-exporter` excluded, deprecated) — catches what render checks miss: probes, image pull, PVC provisioning.

Its **`Lint and unit-test changed charts`** check is required via branch protection.

**[`ci-tooling.yml`](.github/workflows/ci-tooling.yml)** — `helm unittest` + `scripts/ci/kubeconform.sh` against **every** chart; no `ct`, no kind, a handful of seconds. It exists because `ct` only looks under `chart-dirs: [charts]`: a PR that edits `scripts/ci/**` or `.github/ct/**` changes no chart, so every step above skips and `ct lint` exits 0 on zero work. The same blind spot covers the helmignored chart-side inputs `charts/*/ci/kubeconform-overlay.yaml` and `charts/*/tests/**`.

**[`actionlint.yml`](.github/workflows/actionlint.yml)** — type-checks the workflows, so a typo'd `uses:`, undefined context property or bad `if:` fails here instead of during a release. Mirrored by `task actionlint`; install `shellcheck` alongside actionlint, since it is picked up automatically to lint `run:` blocks and CI's image bundles it.

### Why every PR runs all three

All three are required contexts on `main` — `Lint and unit-test changed charts`, `Validate the static tier against every chart`, `Lint workflow files` — and none carries a `paths:` filter, deliberately. A path-filtered check never reports on PRs that miss the filter, so branch protection would wait on it forever. The cost of that is a docs-only PR running the lot: `ci.yml` finds nothing in `ct list-changed`, skips its lint/install steps and reports green in under a minute, while the other two do their (cheap, cluster-free) work in full.

One consequence to know about: **retargeting a PR's base branch does not start a run.** A stacked PR whose base is auto-retargeted to `main` when the parent merges reports no checks at all, and stays unmergeable until you push to it — rebase onto `main` and force-push.

### What counts as "changed" (`use-helmignore`)

`ct.yaml` sets `use-helmignore: true` and every `.helmignore` excludes `/ci/` and `/tests/` — test scaffolding that runs from the repo and is never shipped to consumers. Two consequences:

- **A test-only edit is not a chart change.** Touch only `ci/*-values.yaml` or `tests/*_test.yaml` and the chart drops out of `ct list-changed`: no version bump demanded, no release for scaffolding consumers never receive.
- **That edit gets no `ct` run.** `tests/**` and `ci/kubeconform-overlay.yaml` still get `helm unittest` + `kubeconform` fleet-wide via `ci-tooling.yml`. `ci/*-values.yaml` is in no filter and no cluster-free job, so a broken `ct install` scenario sits unnoticed — run `task test APP=<chart>` locally.

Both patterns are anchored (`/tests/`, not `tests/`) on purpose: unanchored, `tests/` also matches `templates/tests/` and would strip the `helm test` hooks out of the published package.

## Versioning and release

- **`appVersion`** — the upstream image tag (e.g. `v1.7.0`), not SemVer-bound. A `# renovate: datasource=docker depName=<image>` comment above it lets Renovate track upstream.
- **`version`** — the chart SemVer. This is what gates a release.

Pipeline:

1. **Renovate** bumps `appVersion` on an upstream release, then the chart `version` (upstream patch → chart patch; minor/major → chart minor), scoped so only the changed chart bumps. The `helm-values` manager is disabled — image versions live in `appVersion`, never `values.yaml`.
2. On **merge to `main`**, the `release` job in [`release.yml`](.github/workflows/release.yml):
   - **`chart-releaser`** publishes any chart whose `version` changed to the GitHub Pages repo (`CR_SKIP_EXISTING`), leaving the packaged `.tgz` (deps vendored) in `.cr-release-packages/`. It *packages* more than it publishes: the set is a file diff against `git describe --tags --abbrev=0 HEAD~`, which with per-chart tags can resolve to a tag from an older release.
   - a later step `helm push`es those packages to the `homeylabcharts` OCI registry on Docker Hub, **skipping any version already published there**. Pages is immutable by construction; the skip makes OCI match. Without it an unrelated edit republishes an unchanged chart under its existing tag with a new digest — `helm package` is not reproducible across checkouts (file mtimes land in the tarball).

**A templates-only change with an unchanged `version` ships nothing.** Always bump `version` when you want a release.

**If the OCI push fails after Pages published** (auth/network blip), **re-run that workflow run**. Same commit → same packaged set → the guard skips what landed and pushes only what didn't. Don't wait for the next merge: once its own tags move the diff base, a chart it doesn't touch is no longer packaged. Fallback if the run is gone: `task pkg-with-dep APP=<chart>` then `task oci-push FILE=<chart>-<version>.tgz`.

**A published version cannot be corrected in place** on either channel. Supersede it with a new patch version, or delete the tag from *both* (the GitHub Release and its asset, the `gh-pages` `index.yaml` entry, the Docker Hub tag) and let the next merge republish.

### Umbrella charts: release the subchart first

`release.yml` packages a parent by pulling its first-party subcharts *from OCI*, but pushes subcharts to OCI later in the same job. Bumping a subchart **and** the parent's dependency on it in one merge therefore fails — the parent can't find the unpublished version, and the **whole release aborts**, not just that chart.

**Rule:** ship the subchart bump in its own PR, then bump the parent's `dependencies[].version` in a follow-up. `mariadb` is third-party and already published, so it needs no ordering.

### Artifact Hub annotations

`artifacthub.io/*` in `Chart.yaml` is catalog metadata for [artifacthub.io](https://artifacthub.io), **ignored by Helm and the release pipeline**. Not every chart carries them. On charts that do, refresh `artifacthub.io/changes` each release — entries of `{kind, description}` where `kind` is one of `added`, `changed`, `deprecated`, `removed`, `fixed`, `security` (rendered as the version's changelog; `security` also triggers a notification). `artifacthub.io/license` and `artifacthub.io/links` rarely change.

## Gotchas

- **`README.md` is generated — never hand-edit it.** Edit `README.md.gotmpl`, run `task docs APP=<chart>`. Value-table rows come from the `# --` comments in `values.yaml`.
- **Chart `version` must bump or the release is silently skipped.**
- **Breaking-change table covers the current major only.** The README's `### Breaking Changes` table lists the upgrade into the current major plus breaking or destructive upgrades within it, one sentence and a link each; the full text of every version lives in `docs/upgrade.md`. Drop the older rows when a new major lands — the notes keep them.
- **`ci/*-values.yaml` must be self-contained.** `ct install` runs in a fresh namespace, so values referencing pre-existing cluster objects (`existingSecret`, an external PVC/secret) fail with `CreateContainerConfigError` — cover those paths with helm-unittest instead. Keep memory limits generous for JVM/heavy images or `ct install` OOMs before Ready.
- **Adding an off-by-default feature or a passthrough? Add it to the kubeconform overlay.** Anything behind an `enabled`/`create` flag — CRD kinds, but also `serviceAccount.create`, `ingress.enabled` — renders in no default pass. Give it a **real payload** (a `prometheusRule` with an empty `rules` list renders `spec: null` and fails) and **at least two entries** in every list and map (an empty passthrough takes the `{{- else }}` branch and never exercises the `toYaml | nindent` path, which is where indent bugs live).
- **Chart-specific overlay values go in `charts/<chart>/ci/kubeconform-overlay.yaml`**, layered on the fleet-wide file — use it when a key's *shape* differs (v-rising nests `persistence` under `steamServer`/`world`, exportarr nests everything under `exportarr:`). The name must not end in `-values.yaml` or `ct install` picks it up.
- **A green coverage guard is not full coverage.** `kubeconform.sh` fails when a chart declares a passthrough (default `{}`, `[]`, or bare) that neither overlay *populates* — `key: {}` doesn't count. It walks one level only, so nested passthroughs (`metrics.serviceMonitor.relabelings`, `exportarr.apps.<app>[].volumes`) and `""` defaults are on you.
- **`kubeconform` runs *without* `-ignore-missing-schemas`.** A missing schema is a hard failure. Schemas come from the network (kubeconform's default location plus the [datree CRDs-catalog](https://github.com/datreeio/CRDs-catalog)), so upstream breakage can red the gate with no local change. Cached under `.cache/` with no expiry — `rm -rf .cache/` if local disagrees with CI.
- **Clean up local resources** — `task clean-local APP=<chart>` removes the `local-<chart>` release and namespace.
