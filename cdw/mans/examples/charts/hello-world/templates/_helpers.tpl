{{/*
Expand the name of the chart.
*/}}
{{- define "hello-world.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "hello-world.fullname" -}}
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
{{- define "hello-world.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "hello-world.labels" -}}
helm.sh/chart: {{ include "hello-world.chart" . }}
{{ include "hello-world.selectorLabels" . }}
{{- $app := .Values.app }}
{{- $metadata := fromYaml (tpl (.Files.Get "metadata.yaml") .) }}
{{- if hasKey $metadata $app }}
{{- $metaVersion := index $metadata $app "version" }}
{{- $version := default (default (default .Values.image.tag .Chart.AppVersion) $metaVersion) .Values.version }}
{{- $metaManagedBy := index $metadata $app "managedBy" }}
{{- $managedBy := default .Release.Service $metaManagedBy }}
app.kubernetes.io/version: {{ $version }}
app.kubernetes.io/component: {{ index $metadata $app "component" }}
app.kubernetes.io/part-of: {{ index $metadata $app "partOf" }}
app.kubernetes.io/managed-by: {{ $managedBy }}
com.cdw.services/business-unit: {{ index $metadata $app "businessUnit" }}
com.cdw.services/practice: {{ index $metadata $app "practice" }}
com.cdw.services/department: {{ index $metadata $app "department" }}
com.cdw.services/team: {{ index $metadata $app "team" }}
com.cdw.services/environment: {{ index $metadata $app "environment" }}
com.cdw.services/stage: {{ index $metadata $app "stage" }}
com.cdw.services/customer: {{ index $metadata $app "customerAbbreviation" }}
com.cdw.services/pci: {{ index $metadata $app "pci" }}
com.cdw.services/data-classification: {{ index $metadata $app "dataClassification" }}
com.cdw.services/business-criticality: {{ index $metadata $app "businessCriticality" }}
{{- else -}}
app.kubernetes.io/name: {{ include "hello-world.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end -}}
{{- end -}}

{{/*
Selector labels
*/}}
{{- define "hello-world.selectorLabels" -}}
{{- $app := .Values.app -}}
{{- $metadata := fromYaml (tpl (.Files.Get "metadata.yaml") .) -}}
{{- if hasKey $metadata $app -}}
{{- $metaInstance := index $metadata $app "instance" -}}
{{- $instance := default .Release.Name $metaInstance -}}
app.kubernetes.io/name: {{ index $metadata $app "name" }}
app.kubernetes.io/instance: {{ $instance }}
{{- else -}}
app.kubernetes.io/name: {{ include "hello-world.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end -}}
{{- end -}}

{{/*
Create the name of the service account to use
*/}}
{{- define "hello-world.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "hello-world.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}
