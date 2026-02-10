{{- define "voting-app.name" -}}
{{- default .Chart.Name .Values.nameOverride -}}
{{- end -}}

{{- define "voting-app.labels" -}}
app.kubernetes.io/name: {{ include "voting-app.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
helm.sh/chart: {{ .Chart.Name }}-{{ .Chart.Version | replace "+" "_" }}
{{- end -}}

{{- define "voting-app.selectorLabels" -}}
app.kubernetes.io/name: {{ include "voting-app.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end -}}

{{/*
Bitnami subcharts use predictable service names based on the Helm release name.

- Redis replication master service:    <release>-redis-master
- PostgreSQL service:                 <release>-postgresql
*/}}

{{- define "voting-app.redisMasterServiceName" -}}
{{- printf "%s-redis-master" .Release.Name -}}
{{- end -}}

{{- define "voting-app.postgresqlServiceName" -}}
{{- printf "%s-postgresql" .Release.Name -}}
{{- end -}}

{{/*
PostgreSQL secret name:
- If auth.existingSecret is set, use it
- Otherwise, Bitnami postgresql defaults to <release>-postgresql
*/}}
{{- define "voting-app.postgresqlSecretName" -}}
{{- if .Values.postgresql.auth.existingSecret -}}
{{- .Values.postgresql.auth.existingSecret -}}
{{- else -}}
{{- printf "%s-postgresql" .Release.Name -}}
{{- end -}}
{{- end -}}

{{- define "voting-app.postgresqlUserPasswordKey" -}}
{{- default "password" .Values.postgresql.auth.secretKeys.userPasswordKey -}}
{{- end -}}
