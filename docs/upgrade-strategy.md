# Zero/Low-Downtime Paired Upgrade (A+B)

This repo contains a Kubernetes implementation for a **paired stack upgrade** where:

- Component **B depends on A**.
- **A(vN) and B(vN) must match exactly**.
- Cross-version calls are not allowed.

## 1) Prerequisites

Before rollout, ensure the following are in place:

- Kubernetes cluster access with namespace create/apply permissions.
- Ingress controller installed (NGINX in these examples).
- DNS/host mapping for ingress host (example: `api.example.com`).
- Container images for both versions:
  - `ghcr.io/example/component-a:v1.0.0` and `v2.0.0`
  - `ghcr.io/example/component-b:v1.0.0` and `v2.0.0`
- Health endpoints implemented:
  - `/health/ready`
  - `/health/live`
- DB migration plan prepared (expand/backfill/contract or parallel schema).
- Observability dashboards/alerts defined for:
  - 5xx error rate
  - p95/p99 latency
  - pod restart spikes
  - business SLIs

---

## 2) High-Level Architecture (Exact Flow)

### A. Runtime shape

- `v1` stack (blue): `A(v1)` + `B(v1)`
- `v2` stack (green): `A(v2)` + `B(v2)`
- Entry traffic arrives through one ingress/gateway.
- Gateway routes to `B(v1)` and/or `B(v2)`.
- `B(v1)` calls only `A(v1)` and `B(v2)` calls only `A(v2)`.

### B. Rollout sequence

1. Deploy `v2` stack in parallel with `v1`.
2. Validate probes/readiness for `A(v2)` and `B(v2)`.
3. Shift ingress traffic to `B(v2)` gradually (e.g., 10% → 25% → 50% → 100%).
4. Monitor infra + business SLIs at each gate.
5. If healthy, complete cutover to 100% `v2`.
6. Keep `v1` stack for rollback window.
7. Decommission `v1` after soak period and finalize DB contract steps.

### C. Rollback sequence

1. Detect regression in metrics/SLOs.
2. Immediately route traffic back to `v1`.
3. Freeze further DB-contract/destructive changes.
4. Triage and fix in `v2`; redeploy and retry canary.

---

## 3) Troubleshooting Guide

### Issue: `B(v2)` returns 5xx after traffic shift

**Likely causes**
- Wrong `COMPONENT_A_BASE_URL` target.
- `A(v2)` not ready but receiving calls.
- DB migration not complete for `v2` path.

**Checks**
- Confirm overlay patch points to `component-a-v2`.
- Check readiness probe status/events on `A(v2)` pods.
- Check app logs for schema/contract errors.

**Fixes**
- Roll back traffic to `v1`.
- Correct overlay/env value.
- Re-run/repair DB migration.

### Issue: Canary traffic not shifting

**Likely causes**
- Missing/incorrect ingress annotations.
- Wrong ingress class.
- Conflicting ingress resources.

**Checks**
- Inspect ingress annotations and events.
- Confirm ingress controller watches the class used.
- Verify service names/ports exist.

**Fixes**
- Correct annotations/ingress class.
- Re-apply ingress manifests.

### Issue: Old mobile app fails after backend cutover

**Likely causes**
- Client is hitting incompatible backend version.

**Checks**
- Verify header/version routing rules.
- Confirm min-supported app version policy.

**Fixes**
- Temporarily route old app versions to `v1` stack.
- Enforce upgrade gate before retiring `v1`.

### Issue: Validation script fails in CI due cluster connectivity

**Likely causes**
- Script uses cluster-dependent commands.

**Fixes in this repo**
- Use offline render checks (`kubectl kustomize`) and static manifest checks only.

---

## 4) Operational Runbook (Short)

1. `kubectl create namespace app-v1 && kubectl create namespace app-v2`
2. `kubectl apply -k k8s/overlays/v1`
3. `kubectl apply -k k8s/overlays/v2`
4. `kubectl apply -f k8s/ingress-canary-nginx.yaml`
5. Increase canary weights while monitoring.
6. Cut over to 100% v2.
7. Keep rollback window; then clean up v1.

---

## 5) Why this solves strict version coupling

A and B are deployed and routed as one logical release train. No request path should send `B(v1)` to `A(v2)` or `B(v2)` to `A(v1)`.
