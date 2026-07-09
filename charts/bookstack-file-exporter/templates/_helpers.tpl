{{/*
Expand the name of the chart.
*/}}
{{- define "bookstack-file-exporter.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "bookstack-file-exporter.fullname" -}}
{{- if .Values.fullnameOverride }}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- $name := default .Chart.Name .Values.nameOverride }}
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
{{- define "bookstack-file-exporter.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "bookstack-file-exporter.labels" -}}
helm.sh/chart: {{ include "bookstack-file-exporter.chart" . }}
{{ include "bookstack-file-exporter.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "bookstack-file-exporter.selectorLabels" -}}
app.kubernetes.io/name: {{ include "bookstack-file-exporter.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "bookstack-file-exporter.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "bookstack-file-exporter.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}

{{/*
Recursively prune nil / empty-string / empty-list / empty-map values from a map, returning YAML
text of the pruned result. Numbers (including 0) and booleans (including false) are always kept -
only the absence of a value is pruned, never a real zero/false value. Used to render config.yml as
a near-passthrough of `.Values.config` without ever emitting an explicit `null` or an empty typed
field, both of which the upstream v3 exporter rejects at startup.
Usage: {{ include "bookstack-file-exporter.pruneMap" $someMap }}
*/}}
{{- define "bookstack-file-exporter.pruneMap" -}}
{{- $pruned := dict -}}
{{- range $k, $v := . -}}
  {{- if kindIs "map" $v -}}
    {{- $sub := fromYaml (include "bookstack-file-exporter.pruneMap" $v) -}}
    {{- if $sub -}}
      {{- $_ := set $pruned $k $sub -}}
    {{- end -}}
  {{- else if kindIs "slice" $v -}}
    {{- if $v -}}
      {{- $_ := set $pruned $k $v -}}
    {{- end -}}
  {{- else if kindIs "string" $v -}}
    {{- if ne $v "" -}}
      {{- $_ := set $pruned $k $v -}}
    {{- end -}}
  {{- else if not (kindIs "invalid" $v) -}}
    {{- $_ := set $pruned $k $v -}}
  {{- end -}}
{{- end -}}
{{- toYaml $pruned -}}
{{- end -}}
