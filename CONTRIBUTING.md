# Contributing

Thanks for contributing to the homeylab Helm charts. This repo is a **monorepo of independent Helm charts** under `charts/<chart>/`, each wrapping a single upstream app or Prometheus exporter. This guide explains the toolchain, the `Taskfile` that drives it, the layout of a chart, and the workflow from edit to release.

## Table of Contents

- [Prerequisites](#prerequisites)
- [The toolchain — what each tool does](#the-toolchain--what-each-tool-does)
- [The Taskfile — how it helps](#the-taskfile--how-it-helps)
- [Anatomy of a chart](#anatomy-of-a-chart)
- [Testing layers](#testing-layers)
- [Contribution workflow](#contribution-workflow)
- [Commit and PR conventions](#commit-and-pr-conventions)
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

All task commands take the target chart via `APP=<chart>`, e.g. `task verify APP=bookstack`. Run `task` (or `task --list`) to see every target.

## The toolchain — what each tool does

**`helm lint` / `helm template`** — `lint` catches malformed `Chart.yaml`/`values.yaml` and obvious template errors; `template` renders a chart to raw Kubernetes YAML so you (and the tools below) can inspect exactly what gets applied.

**`kubeconform`** — validates the *rendered* manifests against Kubernetes API schemas (checks kinds, required fields, field types). It runs with `-ignore-missing-schemas`, so **CRD-based resources (e.g. `ServiceMonitor`, `HTTPRoute`) are skipped, not validated** — a green kubeconform does not prove those render correctly. Cover CRD manifests with `helm template` + unit tests instead.

**`helm-unittest`** — cluster-free unit tests for templates. Suites live in `charts/<chart>/tests/*_test.yaml` and assert on rendered output (a value renders, a Secret key exists, envFrom targets the right name, a manifest is/ isn't produced). This is where you test logic that `ct install` can't safely exercise (e.g. `existingSecret` paths that reference objects a fresh namespace won't have).

**`chart-testing` (`ct install`)** — actually installs the chart into a throwaway namespace on a **real cluster** (kind) using each value file in `charts/<chart>/ci/*-values.yaml`, and waits for it to become Ready. This is the integration test: it proves the chart *runs*, not just that it renders. Each `ci/*-values.yaml` file is one install scenario and **must be self-contained** (see Gotchas).

**`helm-docs` + `README.md.gotmpl`** — the chart `README.md` is **generated**, not hand-written. `README.md.gotmpl` is the source template; the value table in it (`{{ template "chart.valuesTable" . }}`) is built from the `# --` comments above each key in `values.yaml`. Run `task docs APP=<chart>` to regenerate. Charts *without* a `.gotmpl` keep a hand-written README and are intentionally skipped by `task docs` (helm-docs would clobber them).

**Renovate** — automation (runs in CI, not locally) that bumps a chart's `appVersion` when its upstream image releases, then bumps the chart `version`. See [Versioning and release](#versioning-and-release).

**`chart-releaser`** — the release tool (runs on merge to `main`) that packages and publishes any chart whose `version` changed to the GitHub Pages Helm repo. A second job pushes every chart to the `homeylabcharts` OCI registry on Docker Hub.

## The Taskfile — how it helps

The [`Taskfile.yml`](Taskfile.yml) wraps every tool above behind one consistent, `APP=`-scoped interface so you never memorize raw flags. Targets, grouped by what they're for:

### Validate (run before every commit)

| Task | Runs |
| --- | --- |
| `task lint APP=<chart>` | `helm lint` |
| `task kubeconform APP=<chart>` | `helm template … \| kubeconform -strict -ignore-missing-schemas` (k8s `1.30.0`, override with `K8S_VERSION=`) |
| `task unittest APP=<chart>` | `helm unittest` |
| **`task verify APP=<chart>`** | **`lint` + `kubeconform` + `unittest` — the local gate.** Run this before every commit; it is the only gate before merge. |
| `task template APP=<chart>` | `helm template … --debug` (eyeball the rendered output) |
| `task docs APP=<chart>` | regenerate `README.md` via helm-docs |

### Local cluster (needs a running cluster / current kube-context)

| Task | Runs |
| --- | --- |
| `task test APP=<chart>` | `ct install` against `ci/*-values.yaml` (kind) |
| `task local-template APP=<chart>` | render with your `.local/values/<chart>.yaml` |
| `task dryrun-local APP=<chart>` | `helm upgrade --install --dry-run=client` with local values |
| `task deploy-local APP=<chart>` | install/upgrade with local values into namespace `local-<chart>` |
| `task clean-local APP=<chart>` | delete the local release and its namespace |

> **`deploy-local`/`dryrun-local` use your *current* kube-context** and your credentialed `.local/values/<chart>.yaml` (gitignored). They deploy to whatever cluster `kubectl` points at — confirm `kubectl config current-context` first. Use them to verify runtime behavior the static gate can't catch. Always `task clean-local` afterward.

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
| **Static** | `task lint` + `task kubeconform APP=<chart>` | No | Chart is well-formed and rendered manifests are schema-valid (CRDs skipped — see Gotchas). |
| **Integration** | `task test APP=<chart>` (chart-testing `ct install`) | Yes (kind) | Chart *installs and becomes Ready* on a real cluster for each `ci/*-values.yaml` scenario — and the `helm test` hooks below run automatically at the end. |
| **Live behavior** | `task deploy-local APP=<chart>` → inspect → `task clean-local` | Yes (your context) | Runtime behavior the static layers can't catch — real backend connectivity, env-var semantics, probes under load — using your credentialed `.local/values/<chart>.yaml`. |

**`task verify`** bundles the two cluster-free layers (unit + static) and is the pre-commit gate.

### `helm test` (connection probes)

Each chart ships a `templates/tests/test-connection.yaml` — a Pod annotated `helm.sh/hook: test` that curls/wgets the service and expects a 200. It is **not** a unit test; it runs against a live release:

```bash
# after installing (e.g. task deploy-local APP=<chart>)
helm test <release> -n <namespace>
```

`ct install` (`task test`) runs these hooks **automatically** after the chart reaches Ready, so the connection probe is exercised as part of the integration layer — you rarely need to invoke `helm test` by hand unless you're debugging a `deploy-local` release.

## Contribution workflow

1. **Branch** off `main` — include an issue/ticket number if there is one (e.g. `feat/qbittorrent-exporter-modernization`).
2. **Make your change** in `charts/<chart>/`. If you touched `values.yaml`, update its `# --` comments too.
3. **Regenerate docs** if `values.yaml`, `Chart.yaml`, or `README.md.gotmpl` changed: `task docs APP=<chart>`.
4. **Bump the chart `version`** in `Chart.yaml` (SemVer). **Without a version bump the release is silently skipped** — see [Versioning and release](#versioning-and-release).
5. **Run the gate**: `task verify APP=<chart>` — must be green (lint + kubeconform + unittest).
6. **Optionally integration-test**: `task test APP=<chart>` (kind), and/or `task deploy-local APP=<chart>` against a real cluster for behavior the static gate can't prove. Clean up after (`task clean-local`).
7. **Open a PR** against `main`.

> **There is no PR-level CI.** `release.yml` runs on push to `main` only. `task verify` (plus any integration testing you do) is the real gate — run it yourself before requesting review.

## Commit and PR conventions

- **Commits** follow [Conventional Commits](https://www.conventionalcommits.org/): `feat` (MINOR), `fix` (PATCH); also `refactor`, `chore`, `ci`, `docs`, `test`. Append `!` for breaking changes (e.g. `feat(pihole-exporter)!: …`). Scope commits to a single chart where possible.
- **PR descriptions** should state *what* changed (facts), *why*, and a test plan / verification steps (e.g. the `task verify` result, any live-test output). Call out breaking changes explicitly.

## Versioning and release

Two version fields in `Chart.yaml`, and they move differently:

- **`appVersion`** — the upstream image tag (e.g. `v1.7.0`). Not SemVer-bound. A `# renovate: datasource=docker depName=<image>` comment above it lets Renovate track upstream releases.
- **`version`** — the *chart* SemVer. This is what gates a release.

Pipeline:

1. **Renovate** (CI) bumps `appVersion` when the upstream image releases, then bumps the chart `version` (upstream patch → chart patch; minor/major → chart minor), scoped so only the changed chart bumps. (The `helm-values` manager is disabled — image versions are tracked *only* via `appVersion`, never `values.yaml`.)
2. On **merge to `main`**, [`release.yml`](.github/workflows/release.yml) runs:
   - **`chart-releaser`** publishes any chart whose `Chart.yaml` `version` changed to the GitHub Pages Helm repo (`CR_SKIP_EXISTING` — unchanged versions are skipped).
   - a second job packages **every** chart (with deps) and pushes it to the `homeylabcharts` OCI registry on Docker Hub.

**Consequence:** a templates-only change with an unchanged `version` ships **nothing** via chart-releaser. Always bump `version` when you want a release.

**Artifact Hub annotations** (`artifacthub.io/*` in `Chart.yaml`) are catalog metadata for [artifacthub.io](https://artifacthub.io) — **ignored by Helm and the release pipeline** (they never affect rendering, install, or whether a release ships). Not every chart carries them yet. On charts that do, refresh `artifacthub.io/changes` for each release — a list of `{kind, description}` entries where `kind` is one of `added`, `changed`, `deprecated`, `removed`, `fixed`, `security` (Artifact Hub renders these as the version's changelog; `security` entries also trigger a notification). `artifacthub.io/license` and `artifacthub.io/links` rarely change.

## Gotchas

- **`README.md` is generated — never hand-edit it.** Edit `README.md.gotmpl` and run `task docs APP=<chart>`. Value-table rows come from the `# --` comments in `values.yaml`.
- **Chart `version` must bump or the release is silently skipped.** chart-releaser only publishes a chart whose `version` changed.
- **`ci/*-values.yaml` must be self-contained.** `ct install` runs in a fresh namespace, so values referencing pre-existing cluster objects (`existingSecret`, an external PVC/secret) fail with `CreateContainerConfigError`. Test those paths with helm-unittest (cluster-free) instead. Keep memory limits generous for JVM/heavy images or `ct install` OOMs before Ready.
- **`kubeconform` runs with `-ignore-missing-schemas`**, so CRD-based manifests (HTTPRoute, ServiceMonitor) are skipped, not validated. A green kubeconform does not prove those render correctly — cover them with `helm template` + unittest.
- **Clean up local resources** — `task clean-local APP=<chart>` removes the `local-<chart>` namespace and release after `deploy-local`.
