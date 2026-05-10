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
- `docs/interview-questions-answers.md`: interview Q&A with diagrams
- `scripts/validate-manifests.sh`: local validation script


## Prerequisites

- Kubernetes cluster with `kubectl` access
- NGINX ingress controller (or equivalent with compatible canary features)
- Versioned container images for both components
- DNS/host for ingress target

## Deploy

```bash
kubectl create namespace app-v1
kubectl create namespace app-v2
kubectl apply -k k8s/overlays/v1
kubectl apply -k k8s/overlays/v2
kubectl apply -f k8s/ingress-canary-nginx.yaml
```

Increase canary by editing `nginx.ingress.kubernetes.io/canary-weight`.

## Test / Validate

Run:

```bash
./scripts/validate-manifests.sh
```

This verifies overlays and ingress manifests render successfully with `kubectl kustomize` (fully offline; no cluster connection required).


## Troubleshooting

See `docs/upgrade-strategy.md` for common failure modes and fixes (canary not shifting, mismatched A/B target, client version drift, CI validation issues).
