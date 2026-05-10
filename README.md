# Realtime-Projects

Reference implementation for low-downtime upgrades of two tightly coupled services:

- `component-a` and `component-b`
- `component-b` depends on `component-a`
- both must run the same version

## Layout

- `k8s/base`: base manifests for A and B
- `k8s/overlays/v1`: version 1 stack
- `k8s/overlays/v2`: version 2 stack
- `k8s/ingress-canary-nginx.yaml`: weighted canary at stack level
- `k8s/ingress-version-header-nginx.yaml`: client version-aware routing
- `docs/upgrade-strategy.md`: rollout guidance

## Deploy

```bash
kubectl create namespace app-v1
kubectl create namespace app-v2
kubectl apply -k k8s/overlays/v1
kubectl apply -k k8s/overlays/v2
kubectl apply -f k8s/ingress-canary-nginx.yaml
```

Increase canary by editing `nginx.ingress.kubernetes.io/canary-weight`.
