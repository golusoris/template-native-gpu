{{- define "project.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "project.fullname" -}}
{{- if .Values.fullnameOverride -}}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- printf "%s-%s" .Release.Name (include "project.name" .) | trunc 63 | trimSuffix "-" -}}
{{- end -}}
{{- end -}}

{{- define "project.labels" -}}
app.kubernetes.io/name: {{ include "project.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
helm.sh/chart: {{ printf "%s-%s" .Chart.Name .Chart.Version }}
{{- end -}}

{{- define "project.selectorLabels" -}}
app.kubernetes.io/name: {{ include "project.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end -}}

{{- define "project.serviceAccountName" -}}
{{- if .Values.serviceAccount.create -}}
{{- default (include "project.fullname" .) .Values.serviceAccount.name -}}
{{- else -}}
{{- default "default" .Values.serviceAccount.name -}}
{{- end -}}
{{- end -}}

{{/* GPU resource key for the configured vendor. */}}
{{- define "project.gpuResourceKey" -}}
{{- if eq .Values.gpu.vendor "amd" -}}amd.com/gpu
{{- else if eq .Values.gpu.vendor "intel" -}}gpu.intel.com/i915
{{- else -}}nvidia.com/gpu
{{- end -}}
{{- end -}}

{{/* Shared pod spec template, parameterised by .Values. */}}
{{- define "project.podSpec" -}}
serviceAccountName: {{ include "project.serviceAccountName" . }}
securityContext:
  {{- toYaml .Values.podSecurityContext | nindent 2 }}
{{- with .Values.imagePullSecrets }}
imagePullSecrets:
  {{- toYaml . | nindent 2 }}
{{- end }}
{{- if .Values.gpu.enabled }}
affinity:
  nodeAffinity:
    requiredDuringSchedulingIgnoredDuringExecution:
      nodeSelectorTerms:
        - matchExpressions:
            - key: {{ include "project.gpuResourceKey" . }}
              operator: Exists
{{- else }}
{{- with .Values.affinity }}
affinity:
  {{- toYaml . | nindent 2 }}
{{- end }}
{{- end }}
{{- with .Values.nodeSelector }}
nodeSelector:
  {{- toYaml . | nindent 2 }}
{{- end }}
{{- with .Values.tolerations }}
tolerations:
  {{- toYaml . | nindent 2 }}
{{- end }}
containers:
  - name: {{ include "project.name" . }}
    image: "{{ .Values.image.repository }}:{{ .Values.image.tag | default .Chart.AppVersion }}"
    imagePullPolicy: {{ .Values.image.pullPolicy }}
    securityContext:
      {{- toYaml .Values.securityContext | nindent 6 }}
    {{- with .Values.command }}
    command: {{ toYaml . | nindent 6 }}
    {{- end }}
    {{- with .Values.args }}
    args: {{ toYaml . | nindent 6 }}
    {{- end }}
    {{- with .Values.env }}
    env: {{ toYaml . | nindent 6 }}
    {{- end }}
    resources:
      {{- $res := deepCopy .Values.resources }}
      {{- if .Values.gpu.enabled }}
      {{- $_ := set $res.limits (include "project.gpuResourceKey" .) .Values.gpu.count }}
      {{- end }}
      {{- toYaml $res | nindent 6 }}
    {{- if .Values.service.enabled }}
    ports:
      - name: http
        containerPort: {{ .Values.service.port }}
    {{- end }}
    {{- if .Values.scratch.enabled }}
    volumeMounts:
      - name: scratch
        mountPath: /tmp
    {{- end }}
{{- if .Values.scratch.enabled }}
volumes:
  - name: scratch
    emptyDir:
      sizeLimit: {{ .Values.scratch.sizeLimit }}
{{- end }}
{{- end -}}
