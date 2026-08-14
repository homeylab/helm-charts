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
Create the name of the service account to use
*/}}
{{- define "exportarr.serviceAccountName" -}}
{{- if .Values.exportarr.serviceAccount.create }}
{{- default (include "exportarr.fullname" .) .Values.exportarr.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.exportarr.serviceAccount.name }}
{{- end }}
{{- end }}
