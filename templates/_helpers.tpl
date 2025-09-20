{{/*
Expand the name of the chart.
*/}}
{{- define "itl-k8s-capi.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
*/}}
{{- define "itl-k8s-capi.fullname" -}}
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
{{- define "itl-k8s-capi.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "itl-k8s-capi.labels" -}}
helm.sh/chart: {{ include "itl-k8s-capi.chart" . }}
{{ include "itl-k8s-capi.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- if .Values.global.environment }}
environment: {{ .Values.global.environment }}
{{- end }}
{{- with .Values.labels }}
{{- toYaml . }}
{{- end }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "itl-k8s-capi.selectorLabels" -}}
app.kubernetes.io/name: {{ include "itl-k8s-capi.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Create the name of the vcluster
*/}}
{{- define "itl-k8s-capi.vclusterName" -}}
{{- .Values.vcluster.name | default (printf "%s-%s" .Release.Name "vcluster") }}
{{- end }}

{{/*
Create the namespace for the vcluster
*/}}
{{- define "itl-k8s-capi.vclusterNamespace" -}}
{{- .Values.vcluster.namespace | default .Release.Namespace }}
{{- end }}

{{/*
Create annotations
*/}}
{{- define "itl-k8s-capi.annotations" -}}
{{- with .Values.annotations }}
{{- toYaml . }}
{{- end }}
{{- end }}
