#!/usr/bin/env bash
# Render a chart and validate the manifests against Kubernetes schemas.
# Usage: scripts/ci/kubeconform.sh <chart-dir>   (chart-dir e.g. charts/pihole-exporter)
# Mirrors `task kubeconform`. Invoked per-chart by ct via ct.yaml additional-commands.
set -euo pipefail

chart="$1"
helm template "$(basename "$chart")" "$chart" \
  | kubeconform -strict -summary -ignore-missing-schemas -kubernetes-version 1.30.0
