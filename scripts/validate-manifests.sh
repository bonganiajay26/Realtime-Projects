#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

require_cmd() {
  command -v "$1" >/dev/null 2>&1 || {
    echo "error: required command not found: $1" >&2
    exit 1
  }
}

require_cmd kubectl

echo "Validating kustomize overlays via kubectl kustomize..."
( cd k8s && kubectl kustomize overlays/v1 >/dev/null )
( cd k8s && kubectl kustomize overlays/v2 >/dev/null )

echo "Client-side dry-run apply checks..."
kubectl apply --dry-run=client -k k8s/overlays/v1 >/dev/null
kubectl apply --dry-run=client -k k8s/overlays/v2 >/dev/null
kubectl apply --dry-run=client -f k8s/ingress-canary-nginx.yaml >/dev/null
kubectl apply --dry-run=client -f k8s/ingress-version-header-nginx.yaml >/dev/null

echo "All manifest validations passed."
