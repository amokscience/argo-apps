{{- define "front-end.name" -}}
front-end
{{- end -}}

{{- define "front-end.fullname" -}}
{{ include "front-end.name" . }}
{{- end -}}
