# Zero/Low-Downtime Paired Upgrade (A+B)

This repo now contains a concrete Kubernetes implementation for a **paired stack upgrade** where:

- Component **B depends on A**.
- **A(vN) and B(vN) must match exactly**.
- Cross-version calls are not allowed.

## What is implemented

- Two isolated versioned stacks (`v1`, `v2`) running in parallel.
- Version-pinned internal service discovery (`component-a-v1`, `component-a-v2`, etc.).
- Single public ingress with weighted canary routing at the **stack level**.
- Version-aware routing option for mobile/web clients via header.

## Rollout flow

1. Deploy `v2` stack alongside `v1`.
2. Verify health/readiness for `a-v2` and `b-v2`.
3. Route a small percentage of external traffic to `b-v2`.
4. Increase weight gradually.
5. Flip to 100% on `v2`.
6. Keep `v1` for rollback window, then retire.

## Why this solves the compatibility constraint

A and B are deployed and shifted together as one logical release train. No request path sends `B(v1)` to `A(v2)` or vice versa.
