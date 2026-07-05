{{/*
Expand the name of the chart.
*/}}
{{- define "bookstack.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "bookstack.fullname" -}}
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
{{- define "bookstack.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "bookstack.labels" -}}
helm.sh/chart: {{ include "bookstack.chart" . }}
{{ include "bookstack.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "bookstack.selectorLabels" -}}
app.kubernetes.io/name: {{ include "bookstack.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "bookstack.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "bookstack.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}

{{/*
This is mainly for chart testing, it will try to use release namespace for dynamic namespace names
*/}}
{{- define "bookstack.defaultDatabaseHost" -}}
{{- printf "%s-mariadb.%s.svc.cluster.local" .Release.Name .Release.Namespace }}
{{- end }}

{{/*
Resolve APP_KEY: explicit config.appKey wins; otherwise reuse the value from an
existing chart-managed Secret; otherwise generate a fresh BookStack app key.
Note: `lookup` returns nothing during `helm template`/`--dry-run`, so a fresh key
is generated then. Fine for `helm install/upgrade`, `ct`, and rancher-desktop
(the flows this repo uses). GitOps tools that apply via `helm template`
(ArgoCD/Flux) would mint a NEW key every sync and break sessions/encrypted data —
those users MUST pin `config.appKey`.
*/}}
{{- define "bookstack.appKey" -}}
{{- if .Values.config.appKey -}}
{{- .Values.config.appKey -}}
{{- else -}}
{{- $existing := lookup "v1" "Secret" .Release.Namespace (include "bookstack.fullname" .) -}}
{{- if and $existing $existing.data (hasKey $existing.data "APP_KEY") -}}
{{- index $existing.data "APP_KEY" | b64dec -}}
{{- else -}}
{{- printf "base64:%s" (randBytes 32) -}}
{{- end -}}
{{- end -}}
{{- end }}

{{/*
DB credentials: embedded MariaDB is the source of truth (mariadb.auth.*) when
mariadb.enabled; otherwise use the external config.* values. Keeps BookStack and
the embedded DB from drifting when only one side is overridden.
*/}}
{{- define "bookstack.dbUser" -}}
{{- if .Values.mariadb.enabled -}}{{ .Values.mariadb.auth.username }}{{- else -}}{{ .Values.config.dbUser }}{{- end -}}
{{- end }}
{{- define "bookstack.dbPassword" -}}
{{- if .Values.mariadb.enabled -}}{{ .Values.mariadb.auth.password }}{{- else -}}{{ .Values.config.dbPass }}{{- end -}}
{{- end }}
{{- define "bookstack.dbName" -}}
{{- if .Values.mariadb.enabled -}}{{ .Values.mariadb.auth.database }}{{- else -}}{{ .Values.config.dbDatabase }}{{- end -}}
{{- end }}
