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

echo "Validating ingress manifests contain required top-level fields..."
for f in k8s/ingress-canary-nginx.yaml k8s/ingress-version-header-nginx.yaml; do
  grep -q "^apiVersion:" "$f"
  grep -q "^kind:" "$f"
  grep -q "^metadata:" "$f"
  grep -q "^spec:" "$f"
done

echo "All manifest validations passed (offline checks)."
