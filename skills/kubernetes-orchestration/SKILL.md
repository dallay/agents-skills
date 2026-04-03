---
name: kubernetes-orchestration
version: 1.0.0
description: >
  Kubernetes container orchestration patterns for production workloads: Pod specs, Deployments,
  Services, ConfigMaps, Secrets, Ingress, resource management, health probes, autoscaling,
  and essential kubectl workflows.
triggers:
  - "Kubernetes"
  - "k8s"
  - "kubectl"
  - "kustomization.yaml"
  - "container orchestration"
---

## When to Use

- Deploying containerized applications to Kubernetes clusters.
- Writing or reviewing Deployment, Service, Ingress, or other K8s manifests.
- Configuring health probes, resource limits, autoscaling, or rolling updates.
- Troubleshooting pod scheduling, networking, or configuration issues.
- Setting up Kustomize overlays for multi-environment deployments.

## Critical Patterns

- **Resource Limits Are Mandatory:** ALWAYS set both `requests` and `limits` for CPU and memory. Without them, a single pod can starve the entire node.
- **Health Probes on Every Workload:** ALWAYS define `readinessProbe` and `livenessProbe`. Without readiness probes, traffic routes to unready pods. Without liveness probes, stuck containers are never restarted.
- **Startup Probes for Slow Init:** Use `startupProbe` for applications with long initialization (JVM, large model loading) to avoid premature liveness kills.
- **Never Use `latest` Tag:** Pin image tags to immutable versions or digests. `latest` causes unpredictable deployments and breaks rollback.
- **Namespaces for Isolation:** Separate workloads by team, environment, or domain using namespaces. Apply ResourceQuotas per namespace.
- **Secrets Are Not Encrypted at Rest by Default:** Enable encryption at rest or use external secret managers (Vault, Sealed Secrets, External Secrets Operator).
- **Pod Disruption Budgets:** Always set PDBs for production workloads to prevent all replicas from being evicted during node maintenance.

## Code Examples

### Pod Spec with Complete Health Probes

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: api-server
  labels:
    app: api-server
    version: v1.2.0
spec:
  containers:
    - name: api
      image: myregistry/api-server:1.2.0
      ports:
        - containerPort: 8080
          protocol: TCP
      resources:
        requests:
          cpu: 100m
          memory: 128Mi
        limits:
          cpu: 500m
          memory: 512Mi
      startupProbe:
        httpGet:
          path: /healthz
          port: 8080
        failureThreshold: 30
        periodSeconds: 10
      readinessProbe:
        httpGet:
          path: /ready
          port: 8080
        initialDelaySeconds: 5
        periodSeconds: 10
        timeoutSeconds: 3
        failureThreshold: 3
      livenessProbe:
        httpGet:
          path: /healthz
          port: 8080
        initialDelaySeconds: 15
        periodSeconds: 20
        timeoutSeconds: 5
        failureThreshold: 3
      env:
        - name: DATABASE_URL
          valueFrom:
            secretKeyRef:
              name: db-credentials
              key: url
        - name: LOG_LEVEL
          valueFrom:
            configMapKeyRef:
              name: app-config
              key: log-level
  restartPolicy: Always
```

### Production Deployment with Rolling Updates

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: api-server
  namespace: production
  labels:
    app: api-server
spec:
  replicas: 3
  revisionHistoryLimit: 5
  selector:
    matchLabels:
      app: api-server
  strategy:
    type: RollingUpdate
    rollingUpdate:
      maxSurge: 1
      maxUnavailable: 0
  template:
    metadata:
      labels:
        app: api-server
        version: v1.2.0
    spec:
      terminationGracePeriodSeconds: 60
      containers:
        - name: api
          image: myregistry/api-server:1.2.0
          ports:
            - containerPort: 8080
          resources:
            requests:
              cpu: 200m
              memory: 256Mi
            limits:
              cpu: "1"
              memory: 1Gi
          readinessProbe:
            httpGet:
              path: /ready
              port: 8080
            periodSeconds: 5
          livenessProbe:
            httpGet:
              path: /healthz
              port: 8080
            periodSeconds: 15
---
apiVersion: policy/v1
kind: PodDisruptionBudget
metadata:
  name: api-server-pdb
  namespace: production
spec:
  minAvailable: 2
  selector:
    matchLabels:
      app: api-server
```

### Services: ClusterIP, NodePort, and LoadBalancer

```yaml
# Internal service (default ClusterIP)
apiVersion: v1
kind: Service
metadata:
  name: api-server
  namespace: production
spec:
  selector:
    app: api-server
  ports:
    - port: 80
      targetPort: 8080
      protocol: TCP
---
# External access via LoadBalancer
apiVersion: v1
kind: Service
metadata:
  name: api-server-public
  namespace: production
spec:
  type: LoadBalancer
  selector:
    app: api-server
  ports:
    - port: 443
      targetPort: 8080
      protocol: TCP
```

### ConfigMaps and Secrets

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: app-config
  namespace: production
data:
  log-level: "info"
  max-connections: "100"
  feature-flags.json: |
    {
      "new-dashboard": true,
      "beta-api": false
    }
---
apiVersion: v1
kind: Secret
metadata:
  name: db-credentials
  namespace: production
type: Opaque
stringData:
  url: "postgres://user:pass@db-host:5432/mydb"
  api-key: "sk-secret-value"
```

### Ingress with TLS

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: api-ingress
  namespace: production
  annotations:
    nginx.ingress.kubernetes.io/rate-limit: "100"
    cert-manager.io/cluster-issuer: letsencrypt-prod
spec:
  ingressClassName: nginx
  tls:
    - hosts:
        - api.example.com
      secretName: api-tls-cert
  rules:
    - host: api.example.com
      http:
        paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: api-server
                port:
                  number: 80
```

### Horizontal Pod Autoscaler

```yaml
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: api-server-hpa
  namespace: production
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: api-server
  minReplicas: 3
  maxReplicas: 20
  metrics:
    - type: Resource
      resource:
        name: cpu
        target:
          type: Utilization
          averageUtilization: 70
    - type: Resource
      resource:
        name: memory
        target:
          type: Utilization
          averageUtilization: 80
  behavior:
    scaleDown:
      stabilizationWindowSeconds: 300
      policies:
        - type: Percent
          value: 25
          periodSeconds: 60
    scaleUp:
      stabilizationWindowSeconds: 30
      policies:
        - type: Pods
          value: 4
          periodSeconds: 60
```

### Kustomize Base and Overlay

```yaml
# base/kustomization.yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
resources:
  - deployment.yaml
  - service.yaml
  - ingress.yaml
commonLabels:
  app.kubernetes.io/managed-by: kustomize

# overlays/production/kustomization.yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
resources:
  - ../../base
namespace: production
patches:
  - target:
      kind: Deployment
      name: api-server
    patch: |
      - op: replace
        path: /spec/replicas
        value: 5
      - op: replace
        path: /spec/template/spec/containers/0/resources/limits/memory
        value: 2Gi
```

## Commands

```bash
# Apply manifests
kubectl apply -f manifests/ --namespace=production
kubectl apply -k overlays/production/   # Kustomize

# Deployment management
kubectl rollout status deployment/api-server -n production
kubectl rollout history deployment/api-server -n production
kubectl rollout undo deployment/api-server -n production          # rollback one revision
kubectl rollout undo deployment/api-server --to-revision=3 -n production

# Debugging
kubectl get pods -n production -l app=api-server -o wide
kubectl describe pod <pod-name> -n production
kubectl logs <pod-name> -n production --tail=100 -f
kubectl logs <pod-name> -n production -c <container> --previous   # crashed container

# Resource inspection
kubectl top pods -n production
kubectl get events -n production --sort-by='.lastTimestamp'
kubectl get hpa -n production

# Quick exec into a pod
kubectl exec -it <pod-name> -n production -- /bin/sh

# Dry run and diff before applying
kubectl apply -f deployment.yaml --dry-run=server
kubectl diff -f deployment.yaml
```

## Best Practices

### DO

- Set `requests` AND `limits` on every container.
- Use `readinessProbe` + `livenessProbe` on every workload.
- Pin image tags to immutable versions (`v1.2.0`, not `latest`).
- Use `Namespaces` + `ResourceQuotas` to isolate teams and environments.
- Set `terminationGracePeriodSeconds` to allow clean shutdown.
- Use `PodDisruptionBudget` for production Deployments.
- Use `kubectl diff` and `--dry-run=server` before applying changes.
- Store manifests in version control and deploy via CI/CD.
- Use Kustomize or Helm for environment-specific configuration.
- Set `revisionHistoryLimit` on Deployments to control rollback depth.

### DON'T

- Run containers as root — use `securityContext.runAsNonRoot: true`.
- Store secrets in plain ConfigMaps — use Secret resources or external managers.
- Use `kubectl apply` directly in production without review — use GitOps or CI/CD.
- Set `maxUnavailable` to 100% in rolling updates — guarantees downtime.
- Omit resource requests — causes unpredictable scheduling and node pressure.
- Use `hostNetwork: true` or `hostPort` unless absolutely required.
- Hardcode environment values — use ConfigMaps, Secrets, or Kustomize overlays.
- Ignore pod eviction signals — handle `SIGTERM` gracefully in your application.
