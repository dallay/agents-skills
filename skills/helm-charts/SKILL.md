---
name: helm-charts
description: >-
  Helm chart development and management for Kubernetes: chart structure, template
  functions, values and overrides, dependencies, hooks, testing, and packaging best
  practices. Use when the task involves `Helm`, `Helm chart`, `Chart.yaml`, `Helm
  template`, or `Kubernetes package management`.
license: MIT
metadata:
  version: "1.0.0"
---
## When to Use

- Creating a new Helm chart for a Kubernetes application.
- Writing or reviewing Helm templates (`templates/`, `_helpers.tpl`).
- Managing chart dependencies and multi-chart deployments.
- Configuring hooks for lifecycle events (migrations, backups, cleanup).
- Debugging template rendering issues or failed releases.

## Critical Patterns

- **Named Templates in `_helpers.tpl`:** ALWAYS extract reusable label sets, selectors, and name logic into named templates. Duplicating labels across resources is a maintenance trap.
- **Values Schema Validation:** Provide a `values.schema.json` to catch misconfiguration early, before templates render invalid YAML.
- **Immutable Selectors:** NEVER change `matchLabels` selectors after initial deployment — Kubernetes rejects updates to immutable fields and the release breaks.
- **Quote All Strings in Templates:** Use `{{ .Values.foo | quote }}` for string values to prevent YAML type coercion (`"true"` becomes boolean `true` without quotes).
- **Resource Naming Conventions:** Include release name in resource names via `{{ include "mychart.fullname" . }}` to support multiple installations in the same namespace.
- **Hook Weight and Delete Policy:** Always set `helm.sh/hook-weight` for ordering and `helm.sh/hook-delete-policy` to clean up completed hook resources.

## Code Examples

### Chart Structure

```
mychart/
├── Chart.yaml              # Chart metadata and dependencies
├── Chart.lock              # Locked dependency versions (committed)
├── values.yaml             # Default configuration values
├── values.schema.json      # Optional: JSON Schema for values validation
├── templates/
│   ├── _helpers.tpl        # Named template definitions
│   ├── deployment.yaml
│   ├── service.yaml
│   ├── ingress.yaml
│   ├── configmap.yaml
│   ├── secret.yaml
│   ├── hpa.yaml
│   ├── serviceaccount.yaml
│   └── tests/
│       └── test-connection.yaml
└── charts/                 # Dependency charts (populated by helm dep update)
```

### Chart.yaml

```yaml
apiVersion: v2
name: api-server
description: A Helm chart for the API server application
type: application
version: 0.3.0        # Chart version — bump on template changes
appVersion: "1.2.0"   # Application version — matches container image tag
maintainers:
  - name: platform-team
    email: platform@example.com
dependencies:
  - name: postgresql
    version: "~13.2.0"
    repository: https://charts.bitnami.com/bitnami
    condition: postgresql.enabled
  - name: redis
    version: "~18.6.0"
    repository: https://charts.bitnami.com/bitnami
    condition: redis.enabled
```

### _helpers.tpl — Named Templates

```yaml
{{/*
Chart name, truncated to 63 chars (K8s label limit).
*/}}
{{- define "mychart.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Fully qualified app name: release-chartname, truncated.
*/}}
{{- define "mychart.fullname" -}}
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
Common labels applied to every resource.
*/}}
{{- define "mychart.labels" -}}
helm.sh/chart: {{ include "mychart.chart" . }}
{{ include "mychart.selectorLabels" . }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels — used in both Deployment and Service.
NEVER change these after first install.
*/}}
{{- define "mychart.selectorLabels" -}}
app.kubernetes.io/name: {{ include "mychart.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Chart label: name-version.
*/}}
{{- define "mychart.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}
```

### Deployment Template

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: {{ include "mychart.fullname" . }}
  labels:
    {{- include "mychart.labels" . | nindent 4 }}
spec:
  {{- if not .Values.autoscaling.enabled }}
  replicas: {{ .Values.replicaCount }}
  {{- end }}
  selector:
    matchLabels:
      {{- include "mychart.selectorLabels" . | nindent 6 }}
  template:
    metadata:
      annotations:
        checksum/config: {{ include (print $.Template.BasePath "/configmap.yaml") . | sha256sum }}
      labels:
        {{- include "mychart.labels" . | nindent 8 }}
    spec:
      serviceAccountName: {{ include "mychart.fullname" . }}
      containers:
        - name: {{ .Chart.Name }}
          image: "{{ .Values.image.repository }}:{{ .Values.image.tag | default .Chart.AppVersion }}"
          imagePullPolicy: {{ .Values.image.pullPolicy }}
          ports:
            - name: http
              containerPort: {{ .Values.service.targetPort }}
              protocol: TCP
          {{- with .Values.resources }}
          resources:
            {{- toYaml . | nindent 12 }}
          {{- end }}
          {{- with .Values.livenessProbe }}
          livenessProbe:
            {{- toYaml . | nindent 12 }}
          {{- end }}
          {{- with .Values.readinessProbe }}
          readinessProbe:
            {{- toYaml . | nindent 12 }}
          {{- end }}
          env:
            - name: APP_ENV
              value: {{ .Values.environment | quote }}
            {{- range $key, $value := .Values.extraEnv }}
            - name: {{ $key }}
              value: {{ $value | quote }}
            {{- end }}
```

### values.yaml

```yaml
replicaCount: 2

image:
  repository: myregistry/api-server
  pullPolicy: IfNotPresent
  tag: ""   # Defaults to Chart.appVersion

service:
  type: ClusterIP
  port: 80
  targetPort: 8080

ingress:
  enabled: false
  className: nginx
  annotations: {}
  hosts:
    - host: api.example.com
      paths:
        - path: /
          pathType: Prefix
  tls: []

resources:
  requests:
    cpu: 100m
    memory: 128Mi
  limits:
    cpu: 500m
    memory: 512Mi

autoscaling:
  enabled: false
  minReplicas: 2
  maxReplicas: 10
  targetCPUUtilizationPercentage: 70

environment: production
extraEnv: {}

livenessProbe:
  httpGet:
    path: /healthz
    port: http
  initialDelaySeconds: 15
  periodSeconds: 20

readinessProbe:
  httpGet:
    path: /ready
    port: http
  initialDelaySeconds: 5
  periodSeconds: 10

postgresql:
  enabled: true

redis:
  enabled: false
```

### Hooks: Pre-upgrade Database Migration

```yaml
apiVersion: batch/v1
kind: Job
metadata:
  name: {{ include "mychart.fullname" . }}-migrate
  labels:
    {{- include "mychart.labels" . | nindent 4 }}
  annotations:
    helm.sh/hook: pre-upgrade,pre-install
    helm.sh/hook-weight: "-5"
    helm.sh/hook-delete-policy: before-hook-creation,hook-succeeded
spec:
  backoffLimit: 3
  template:
    spec:
      restartPolicy: Never
      containers:
        - name: migrate
          image: "{{ .Values.image.repository }}:{{ .Values.image.tag | default .Chart.AppVersion }}"
          command: ["./migrate", "--direction", "up"]
          env:
            - name: DATABASE_URL
              valueFrom:
                secretKeyRef:
                  name: {{ include "mychart.fullname" . }}-db
                  key: url
```

### Helm Test

```yaml
# templates/tests/test-connection.yaml
apiVersion: v1
kind: Pod
metadata:
  name: {{ include "mychart.fullname" . }}-test
  labels:
    {{- include "mychart.labels" . | nindent 4 }}
  annotations:
    helm.sh/hook: test
    helm.sh/hook-delete-policy: before-hook-creation,hook-succeeded
spec:
  restartPolicy: Never
  containers:
    - name: curl-test
      image: curlimages/curl:8.5.0
      command:
        - curl
        - --fail
        - --silent
        - --show-error
        - http://{{ include "mychart.fullname" . }}:{{ .Values.service.port }}/healthz
```

## Commands

```bash
# Create a new chart scaffold
helm create mychart

# Render templates locally (catch errors before deploying)
helm template my-release ./mychart -f values-prod.yaml

# Lint chart for issues
helm lint ./mychart -f values-prod.yaml

# Dependency management
helm dependency update ./mychart
helm dependency list ./mychart

# Install / upgrade / rollback
helm install my-release ./mychart -n production --create-namespace -f values-prod.yaml
helm upgrade my-release ./mychart -n production -f values-prod.yaml --wait --timeout 5m
helm rollback my-release 2 -n production

# Inspect releases
helm list -n production
helm history my-release -n production
helm get values my-release -n production
helm get manifest my-release -n production

# Run tests
helm test my-release -n production

# Debug template rendering
helm template my-release ./mychart --debug 2>&1 | head -100
helm install my-release ./mychart --dry-run --debug
```

## Best Practices

### DO

- Extract repeated label/name logic into `_helpers.tpl` named templates.
- Use `{{ .Values.foo | quote }}` for string values to prevent YAML type issues.
- Add `checksum/config` annotations to trigger pod restarts on ConfigMap changes.
- Set `helm.sh/hook-delete-policy` on every hook to avoid resource buildup.
- Use `--wait` and `--timeout` on `helm upgrade` in CI/CD pipelines.
- Run `helm lint` and `helm template` in CI before deploying.
- Version `Chart.yaml` independently from `appVersion` — chart structure changes need their own version.
- Use `condition` fields in dependencies to allow toggling sub-charts via values.
- Provide sensible defaults in `values.yaml` that work for local development.
- Use `helm diff` plugin (`helm diff upgrade ...`) to preview changes before applying.

### DON'T

- Modify `matchLabels` selectors after the first release — causes immutable field errors.
- Use `helm install` without `--create-namespace` when targeting a new namespace.
- Hardcode release-specific names — always use `{{ include "mychart.fullname" . }}`.
- Skip `helm.sh/hook-weight` when multiple hooks exist — execution order becomes random.
- Commit `charts/` directory contents — commit `Chart.lock` and run `helm dep update` in CI.
- Use `lookup` function without fallback — it returns empty during `helm template` (no cluster).
- Nest `{{ toYaml }}` without `nindent` — produces broken indentation in rendered manifests.
- Override values with `--set` in production — use versioned `-f values-prod.yaml` files for auditability.
