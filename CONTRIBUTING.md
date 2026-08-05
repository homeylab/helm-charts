# Contributing

Thanks for contributing to the homeylab Helm charts. This repo is a **monorepo of independent Helm charts** under `charts/<chart>/`, each wrapping a single upstream app or Prometheus exporter. This guide covers the tooling and the `Taskfile` that drives it, the layout of a chart, and the workflow from edit to release.

## Table of Contents

- [Prerequisites](#prerequisites)
- [The Taskfile — how it helps](#the-taskfile--how-it-helps)
- [Anatomy of a chart](#anatomy-of-a-chart)
- [Testing layers](#testing-layers)
- [Contribution workflow](#contribution-workflow)
- [Commit and PR conventions](#commit-and-pr-conventions)
- [Continuous integration](#continuous-integration)
- [Versioning and release](#versioning-and-release)
- [Gotchas](#gotchas)

## Prerequisites

Install these tools (a [`.devcontainer`](.devcontainer/) is provided that builds a chart-testing image with the toolchain if you prefer a container):

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

All task commands take the target chart via `APP=<chart>`, e.g. `task verify APP=bookstack`. Run `task` (or `task --list`) to see every target.

## The Taskfile — how it helps

The [`Taskfile.yml`](Taskfile.yml) wraps every tool above behind one consistent, `APP=`-scoped interface so you never memorize raw flags. Targets, grouped by what they're for:

### Validate (run before every commit)

| Task | Runs |
| --- | --- |
| `task lint APP=<chart>` | `helm lint` |
| `task kubeconform APP=<chart>` | `scripts/ci/kubeconform.sh` — validates rendered manifests against k8s + CRD schemas (k8s `1.30.0`, override with `K8S_VERSION=`) |
| `task unittest APP=<chart>` | `helm unittest` |
| **`task verify APP=<chart>`** | **`lint` + `kubeconform` + `unittest` — the local mirror of the CI gate's cluster-free layers ([Continuous integration](#continuous-integration)).** Run before every commit. |
| `task template APP=<chart>` | `helm template … --debug` (eyeball the rendered output) |
| `task docs APP=<chart>` | regenerate `README.md` via helm-docs |
| `task actionlint` | `actionlint` over `.github/workflows/` — repo-wide, no `APP=`. Only needed when you touch a workflow. |

### Local cluster (needs a running cluster / current kube-context)

| Task | Runs |
| --- | --- |
| `task test APP=<chart>` | `ct install` against `ci/*-values.yaml` (kind) |
| `task local-template APP=<chart>` | render with your `.local/values/<chart>.yaml` |
| `task dryrun-local APP=<chart>` | `helm upgrade --install --dry-run=client` with local values |
| `task deploy-local APP=<chart>` | install/upgrade with local values into namespace `local-<chart>` |
| `task clean-local APP=<chart>` | delete the local release and its namespace |

> **`deploy-local`/`dryrun-local` use your *current* kube-context** and your credentialed `.local/values/<chart>.yaml` (gitignored). They deploy to whatever cluster `kubectl` points at — confirm `kubectl config current-context` first. Use them to verify runtime behavior the static gate can't catch. Always `task clean-local` afterward.

#### Spinning up a throwaway kind cluster (isolated kubeconfig)

`task test` (`ct install`) needs a running cluster. Point `KUBECONFIG` at a dedicated file before creating the cluster: `kind create cluster` merges into whatever `KUBECONFIG` resolves to (default `~/.kube/config`) and sets its current-context, so an unqualified create can repoint `kubectl` away from a real cluster.

```bash
# 1. Create the cluster in a dedicated kubeconfig file (not your real one)
export KUBECONFIG=/tmp/kind-ct.kubeconfig
kind create cluster --name ct-test --kubeconfig "$KUBECONFIG"

# 2. Run the integration layer against it (task test reads the current context)
task test APP=<chart>

# 3. Tear it down — removes the cluster AND its entries from the kubeconfig
kind delete cluster --name ct-test
rm -f "$KUBECONFIG"          # optional: drop the now-empty isolated kubeconfig
unset KUBECONFIG             # back to your normal ~/.kube/config
```

Heavy charts (`bookstack`, `v-rising`) need a few minutes to reach Ready — add `--helm-extra-args "--timeout 600s"` if invoking `ct` directly.

### Package / release (mostly CI; available locally)

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
├── templates/
│   ├── *.yaml              # manifests
│   ├── _helpers.tpl        # named templates (labels, names, …)
│   ├── NOTES.txt           # post-install notes
│   └── tests/              # `helm test` connection probes (a running-cluster smoke check,
│                           #  distinct from the unit tests below)
├── tests/*_test.yaml       # helm-unittest suites (+ tests/__snapshot__/)
└── ci/*-values.yaml        # one file per `ct install` scenario (must be self-contained)
```

`bookstack` is the outlier: it has subchart dependencies (`mariadb`, `bookstack-file-exporter`); most charts wrap a single upstream image.

## Testing layers

The chart has four independent test layers, cheapest and fastest first. Use the lower layers for logic and the upper layers to prove it actually runs.

| Layer | Tool / command | Needs a cluster? | What it proves |
| --- | --- | --- | --- |
| **Unit** | `task unittest APP=<chart>` (helm-unittest, `tests/*_test.yaml`) | No | Templates render the right output for given values — Secret keys, env wiring, conditionals, which manifests appear. Best place for `existingSecret`/edge-case paths. |
| **Static** | `task lint` + `task kubeconform APP=<chart>` | No | Chart is well-formed and rendered manifests are schema-valid, CRD kinds included. Catches what unittest can't: wrong field names and wrong types. |
| **Integration** | `task test APP=<chart>` (chart-testing `ct install`) | Yes (kind) | Chart *installs and becomes Ready* on a real cluster for each `ci/*-values.yaml` scenario — and the `helm test` hooks below run automatically at the end, unless the scenario disables them (see [`helm test`](#helm-test-connection-probes)). |
| **Live behavior** | `task deploy-local APP=<chart>` → inspect → `task clean-local` | Yes (your context) | Runtime behavior the static layers can't catch — real backend connectivity, env-var semantics, probes under load — using your credentialed `.local/values/<chart>.yaml`. |

**`task verify`** bundles the two cluster-free layers (unit + static) and is the pre-commit gate.

### `helm test` (connection probes)

Most charts ship a `templates/tests/test-connection.yaml` — a Pod annotated `helm.sh/hook: test` that curls/wgets the service and expects a 200. It is **not** a unit test; it runs against a live release. (`bookstack-file-exporter` and `v-rising` ship no probe: neither serves an HTTP endpoint to probe.)

```bash
# after installing (e.g. task deploy-local APP=<chart>)
helm test <release> -n <namespace>
```

`ct install` (`task test`) runs these hooks **automatically** after the chart reaches Ready, so the connection probe is normally exercised as part of the integration layer — you rarely need to invoke `helm test` by hand unless you're debugging a `deploy-local` release.

**Exception — a probe that cannot pass without a live backend.** Some exporters serve an error until they can scrape their upstream, so their probe can never go green in a `ct install` namespace (which has no backend). Those charts gate the hook behind `tests.enabled` (default `true`) and their `ci/*-values.yaml` set it to `false`, so `ct install` verifies Deployment readiness only. `qbittorrent-exporter` is the current case: martabal's exporter serves 503 on `/metrics` until it reaches a live qBittorrent and redirects other paths there, so a wget probe follows the redirect into the 503. Prefer a backend-independent readiness probe where the upstream offers one (`tdarr-exporter` keeps its probe on because `/healthz` is independent of `config.url`). Reach for the gate only when the upstream gives you nothing probeable.

## Contribution workflow

1. **Branch** off `main` — include an issue/ticket number if there is one (e.g. `feat/qbittorrent-exporter-modernization`).
2. **Make your change** in `charts/<chart>/`. If you touched `values.yaml`, update its `# --` comments too.
3. **Regenerate docs** if `values.yaml`, `Chart.yaml`, or `README.md.gotmpl` changed: `task docs APP=<chart>`.
4. **Bump the chart `version`** in `Chart.yaml` (SemVer). **Without a version bump the release is silently skipped** — see [Versioning and release](#versioning-and-release).
5. **Run the gate**: `task verify APP=<chart>` — must be green (lint + kubeconform + unittest).
6. **Optionally integration-test**: `task test APP=<chart>` (kind), and/or `task deploy-local APP=<chart>` against a real cluster for behavior the static gate can't prove. Clean up after (`task clean-local`).
7. **Open a PR** against `main`.

> **CI runs on your PR** — [`ci.yml`](.github/workflows/ci.yml) lints, unit-tests, and installs changed charts, and branch protection blocks merge until it passes ([Continuous integration](#continuous-integration)). Run `task verify` first.

## Commit and PR conventions

- **Commits** follow [Conventional Commits](https://www.conventionalcommits.org/): `feat` (MINOR), `fix` (PATCH); also `refactor`, `chore`, `ci`, `docs`, `test`. Append `!` for breaking changes (e.g. `feat(pihole-exporter)!: …`). Scope commits to a single chart where possible.
- **PR descriptions** should state *what* changed (facts), *why*, and a test plan / verification steps (e.g. the `task verify` result, any live-test output). Call out breaking changes explicitly.

## Continuous integration

[`ci.yml`](.github/workflows/ci.yml) runs on every PR to `main`, driven by `ct` (chart-testing) — [`.github/ct/ct.yaml`](.github/ct/ct.yaml) is the single source of truth, mirrored locally by `task verify`. For each chart changed vs `main` (so the gate scales with your diff):

1. **`ct lint`** — `helm lint` + yamllint + yamale schema + **`--check-version-increment`**: fails unless `Chart.yaml` `version` exceeds `main`'s, so a change under `charts/<chart>/` — outside `ci/` and `tests/`, see [below](#what-counts-as-changed-use-helmignore) — needs a version bump.
2. **`helm unittest` + `kubeconform`** (via `additional-commands`).
3. **`ct install`** on kind — installs each changed chart and waits for Ready (`nut-exporter` excluded, deprecated), catching failures the render checks miss (probes, image pull, PVC provisioning).

The **`Lint and unit-test changed charts`** check is required via branch protection — a red gate blocks merge.

### When the tooling itself changes

`ct` only ever looks under `chart-dirs: [charts]`, so a PR that edits the validation tier — `scripts/ci/**` or `.github/ct/**` — changes no chart, and every step above skips. `ct lint` is no safety net either: with nothing changed it prints `All charts linted successfully` and exits 0 on zero work. The same hole swallows the chart-side inputs `ct` cannot see, because they are helmignored: `charts/*/ci/kubeconform-overlay.yaml` and `charts/*/tests/**`.

[`ci-tooling.yml`](.github/workflows/ci-tooling.yml) covers all of those. It triggers on the static tier *and* on those two chart-side paths, and runs `helm unittest` + `scripts/ci/kubeconform.sh` against **every** chart — no `ct`, no kind, a handful of seconds. Editing the gate proves the gate still works fleet-wide; adding a unit-test suite gets it run.

It is not a required status check, though — a path-filtered check never reports on PRs that miss the filter, so branch protection would wait on it forever (same reasoning as `actionlint.yml` below, resolved the other way). Treat a red `ci-tooling` as blocking by convention, not by mechanism.

The workflows themselves are the other half: nothing validated *them*, so a typo'd `uses:`, an undefined context property or a bad `if:` expression would merge silently and surface when a release failed. [`actionlint.yml`](.github/workflows/actionlint.yml) type-checks the lot. It runs on **every** PR rather than filtering on `.github/workflows/**`: it costs seconds, and a path-filtered check can never be required by branch protection — PRs that miss the filter never report it, so the merge blocks forever waiting on a status that will never arrive.

Mirrored locally by `task actionlint`. Install `shellcheck` alongside actionlint: it gets picked up automatically to lint `run:` blocks, and CI's pinned image bundles it, so without it locally you get a weaker check than the gate.

### What counts as "changed" (`use-helmignore`)

`ct.yaml` sets `use-helmignore: true`, and every chart's `.helmignore` excludes `/ci/` and `/tests/` (`nut-exporter` included, since 1.1.1 — it has a `ci/` overlay but no `tests/`). Those paths are test scaffolding: they are run *from the repo* and are not shipped to chart consumers. Two consequences:

- **A test-only edit is not a chart change.** Touch only `ci/*-values.yaml` or `tests/*_test.yaml` and the chart drops out of `ct list-changed` — no version bump is demanded, and no release is published for scaffolding that consumers never receive.
- **The flip side: that edit gets no `ct` run.** No `ct lint`, no version-increment check, no `ct install` until the chart itself changes. How much else runs depends on *which* scaffolding you touched:
  - `tests/**` and `ci/kubeconform-overlay.yaml` are in [`ci-tooling.yml`](.github/workflows/ci-tooling.yml)'s path filter, so `helm unittest` and `kubeconform` still run — fleet-wide, not just on your chart.
  - `ci/*-values.yaml` is in no filter and consumed by no cluster-free job, so a broken `ct install` scenario sits unnoticed. Run `task test APP=<chart>` locally.

Both patterns are anchored (`/ci/`, not `ci/`) on purpose: an unanchored `tests/` also matches `templates/tests/` and would strip the `helm test` hooks out of the published package.

## Versioning and release

Two version fields in `Chart.yaml`, and they move differently:

- **`appVersion`** — the upstream image tag (e.g. `v1.7.0`). Not SemVer-bound. A `# renovate: datasource=docker depName=<image>` comment above it lets Renovate track upstream releases.
- **`version`** — the *chart* SemVer. This is what gates a release.

Pipeline:

1. **Renovate** (CI) bumps `appVersion` when the upstream image releases, then bumps the chart `version` (upstream patch → chart patch; minor/major → chart minor), scoped so only the changed chart bumps. (The `helm-values` manager is disabled — image versions are tracked *only* via `appVersion`, never `values.yaml`.)
2. On **merge to `main`**, the single `release` job in [`release.yml`](.github/workflows/release.yml) runs:
   - **`chart-releaser`** publishes any chart whose `Chart.yaml` `version` changed to the GitHub Pages Helm repo (`CR_SKIP_EXISTING` — unchanged versions are skipped), leaving the packaged `.tgz` (deps vendored) in `.cr-release-packages/`.
   - a later step in the same job `helm push`es those same packages to the `homeylabcharts` OCI registry on Docker Hub — so OCI publishes **only** the charts Pages just did, and a failed release blocks the push (the two channels can't desync).

**Consequence:** a templates-only change with an unchanged `version` ships **nothing** via chart-releaser. Always bump `version` when you want a release.

**If the OCI push step fails after the release already published to Pages** (e.g. a Docker Hub auth/network blip), re-running the job won't republish it — `chart-releaser` now sees the version as already released and repackages nothing, leaving `.cr-release-packages/` empty. Recover manually for the affected chart: `task pkg-with-dep APP=<chart>` then `task oci-push FILE=<chart>-<version>.tgz`.

### Umbrella charts: release the subchart first

Two charts bundle **first-party** subcharts from the OCI registry — `bookstack` (→ `bookstack-file-exporter`) and `exportarr` (→ `qbittorrent-exporter`, `tdarr-exporter`). At release, `release.yml` packages the parent by pulling those subcharts *from OCI*, but the step that pushes subcharts to OCI runs later in the same job. So bumping a subchart **and** the parent's dependency on it in one merge fails — the parent can't find the not-yet-published subchart version, and the **whole release aborts** (not just that chart).

**Rule:** ship the subchart bump in its own PR first (it lands in OCI + Pages), then bump the parent's `dependencies[].version` to match in a follow-up PR. `mariadb` is third-party and already published, so it needs no ordering.

**Artifact Hub annotations** (`artifacthub.io/*` in `Chart.yaml`) are catalog metadata for [artifacthub.io](https://artifacthub.io) — **ignored by Helm and the release pipeline** (they never affect rendering, install, or whether a release ships). Not every chart carries them yet. On charts that do, refresh `artifacthub.io/changes` for each release — a list of `{kind, description}` entries where `kind` is one of `added`, `changed`, `deprecated`, `removed`, `fixed`, `security` (Artifact Hub renders these as the version's changelog; `security` entries also trigger a notification). `artifacthub.io/license` and `artifacthub.io/links` rarely change.

## Gotchas

- **`README.md` is generated — never hand-edit it.** Edit `README.md.gotmpl` and run `task docs APP=<chart>`. Value-table rows come from the `# --` comments in `values.yaml`.
- **Chart `version` must bump or the release is silently skipped.** chart-releaser only publishes a chart whose `version` changed.
- **`ci/*-values.yaml` must be self-contained.** `ct install` runs in a fresh namespace, so values referencing pre-existing cluster objects (`existingSecret`, an external PVC/secret) fail with `CreateContainerConfigError`. Test those paths with helm-unittest (cluster-free) instead. Keep memory limits generous for JVM/heavy images or `ct install` OOMs before Ready.
- **Adding an off-by-default feature, or a passthrough? Add it to the kubeconform overlay.** Anything gated behind an `enabled`/`create` flag — the CRD kinds, but also `serviceAccount.create`, `ingress.enabled` and friends — renders in no default pass, so the overlay is what makes it render for validation. Miss it and nothing tests your manifest. Two rules: give it a **real payload** (a `prometheusRule` with an empty `rules` list renders `spec: null` and fails), and give every list and map **at least two entries** (an empty passthrough takes the `{{- else }}` branch and never exercises the `toYaml | nindent` path, which is where indent bugs live).
- **Chart-specific values go in `charts/<chart>/ci/kubeconform-overlay.yaml`**, layered on top of the fleet-wide file. Use it when a key's *shape* differs from the fleet — v-rising nests `persistence` under `steamServer`/`world`, exportarr nests everything under `exportarr:`. The name must not end in `-values.yaml` or `ct install` picks it up and needs CRDs in kind.
- **A green coverage guard is not full coverage.** `kubeconform.sh` fails when a chart declares a passthrough (default `{}`, `[]`, or bare) that neither overlay *populates* — `key: {}` doesn't count. It walks one level only, so nested passthroughs (`metrics.serviceMonitor.relabelings`, `exportarr.apps.<app>[].volumes`) and `""` defaults are on you: populate them by hand and cover them in unit tests.
- **`kubeconform` deliberately runs *without* `-ignore-missing-schemas`.** A missing schema is a hard failure, not a silent skip. Schemas come from the network (kubeconform's default location plus the [datree CRDs-catalog](https://github.com/datreeio/CRDs-catalog)), so upstream breakage can red the gate with no local change. Cached under `.cache/` with no expiry — `rm -rf .cache/` if local disagrees with CI.
- **Clean up local resources** — `task clean-local APP=<chart>` removes the `local-<chart>` namespace and release after `deploy-local`.
