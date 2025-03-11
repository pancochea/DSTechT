{{/*
Expand the name of the chart.
*/}}
{{- define "haystack.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "haystack.fullname" -}}
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

{{- define "haystack.commonLabels" -}}
helm.sh/chart: {{ include "haystack.chart" . }}
app.kubernetes.io/name: {{ include "haystack.name" . }}
app.kubernetes.io/version: {{ default .Chart.Version .Chart.AppVersion | quote }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{- define "haystack.backend.commonLabels" -}}
{{- include "haystack.commonLabels" . }}
app.kubernetes.io/component: backend
{{- end }}

{{- define "haystack.frontend.fullname" -}}
{{ include "haystack.name" . }}-frontend
{{- end }}

{{- define "haystack.backend.query.fullname" -}}
{{ include "haystack.name" . }}-backend-query
{{- end }}

{{- define "haystack.backend.index.fullname" -}}
{{ include "haystack.name" . }}-backend-index
{{- end }}

{{- define "haystack.backend.config.fullname" -}}
{{ include "haystack.name" . }}-backend-common-config
{{- end }}

{{- define "haystack.backend.secrets.fullname" -}}
{{ include "haystack.name" . }}-backend-common-secrets
{{- end }}

{{- define "haystack.backend.indexLabels" -}}
{{- include "haystack.backend.commonLabels" . }}
app.kubernetes.io/instance: {{ include "haystack.backend.index.fullname" . }}
{{- end }}

{{- define "haystack.backend.queryLabels" -}}
{{- include "haystack.backend.commonLabels" . }}
app.kubernetes.io/instance: {{ include "haystack.backend.query.fullname" . }}
{{- end }}

{{- define "haystack.frontend.commonLabels" -}}
{{- include "haystack.commonLabels" . }}
app.kubernetes.io/component: frontend
app.kubernetes.io/instance: {{ include "haystack.frontend.fullname" . }}
{{- end }}

{{- define "haystack.frontend.config.fullname" -}}
{{ include "haystack.name" . }}-frontend-config
{{- end }}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "haystack.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

