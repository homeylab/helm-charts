{{/*
Expand the name of the chart.
*/}}
{{- define "exportarr.name" -}}
{{- default .Chart.Name .Values.exportarr.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "exportarr.fullname" -}}
{{- if .Values.exportarr.fullnameOverride }}
{{- .Values.exportarr.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- $name := default .Chart.Name .Values.exportarr.nameOverride }}
{{- if contains $name .Release.Name }}
{{- .Release.Name | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}
{{- end }}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "exportarr.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "exportarr.labels" -}}
helm.sh/chart: {{ include "exportarr.chart" . }}
{{ include "exportarr.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "exportarr.selectorLabels" -}}
app.kubernetes.io/name: {{ include "exportarr.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Effective metrics switch for a single app instance.

exportarr.metrics.enabled is the umbrella-wide default; apps.<app>[].metrics.enabled
overrides it per instance. A define can only return a string, so this returns "true"
when metrics are on and "" when they are off - callers compare:

  {{- $metricsEnabled := eq (include "exportarr.metricsEnabled" (dict "app" $app "root" $)) "true" -}}

Takes a dict of:
  app  - one entry from apps.<app>[]
  root - the root context ($)
*/}}
{{- define "exportarr.metricsEnabled" -}}
{{- $enabled := .root.Values.exportarr.metrics.enabled -}}
{{- if .app.metrics -}}
{{- if hasKey .app.metrics "enabled" -}}
{{- $enabled = .app.metrics.enabled -}}
{{- end -}}
{{- end -}}
{{- if $enabled -}}true{{- end -}}
{{- end }}

{{/*
Per-instance resource name, used as metadata.name and as the
app.kubernetes.io/component label value - both capped at 63 by the API.
Nothing before install catches an overflow (JSON schemas don't encode length),
so fail here where the message can name the fix. Not truncated on purpose: the
suffix is the instance discriminator and sits in the Deployment's immutable
spec.selector, so shortening it would collide instances or break helm upgrade.
*/}}
{{- define "exportarr.appName" -}}
{{- $name := printf "%s-%s-%s" (include "exportarr.fullname" .root) .appKey .instanceName -}}
{{- if gt (len $name) 63 -}}
{{- fail (printf "exportarr: generated name %q is %d characters, over the Kubernetes 63-character limit for Service names and label values. Shorten the release name or apps.%s[].name, or set exportarr.fullnameOverride." $name (len $name) .appKey) -}}
{{- end -}}
{{- $name -}}
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "exportarr.serviceAccountName" -}}
{{- if .Values.exportarr.serviceAccount.create }}
{{- default (include "exportarr.fullname" .) .Values.exportarr.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.exportarr.serviceAccount.name }}
{{- end }}
{{- end }}
