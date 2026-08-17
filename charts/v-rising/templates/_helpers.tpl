{{/*
Expand the name of the chart.
*/}}
{{- define "v-rising.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "v-rising.fullname" -}}
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
RCON Service name. The "-rcon" is appended outside v-rising.fullname, so the
helper's trunc 63 does not cover it and a long release name pushes the Service
name past the API's 63-character cap - which nothing catches before install,
since JSON schemas don't encode length. Fail here instead. Not truncated: the
suffix is what keeps this Service from colliding with the game one.
*/}}
{{- define "v-rising.rconServiceName" -}}
{{- $name := printf "%s-rcon" (include "v-rising.fullname" .) -}}
{{- if gt (len $name) 63 -}}
{{- fail (printf "v-rising: the RCON Service name %q is %d characters, over the Kubernetes 63-character limit. Shorten the release name or set fullnameOverride." $name (len $name)) -}}
{{- end -}}
{{- $name -}}
{{- end }}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "v-rising.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "v-rising.labels" -}}
helm.sh/chart: {{ include "v-rising.chart" . }}
{{ include "v-rising.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "v-rising.selectorLabels" -}}
app.kubernetes.io/name: {{ include "v-rising.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "v-rising.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "v-rising.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}
