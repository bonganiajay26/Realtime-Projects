#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

kustomize_render() {
  local target="$1"
  if command -v kustomize >/dev/null 2>&1; then
    kustomize build "$target"
  elif command -v kubectl >/dev/null 2>&1; then
    kubectl kustomize "$target"
  else
    echo "error: neither 'kustomize' nor 'kubectl' is installed" >&2
    exit 1
  fi
}

echo "Validating kustomize overlays via offline render..."
( cd k8s && kustomize_render overlays/v1 >/dev/null )
( cd k8s && kustomize_render overlays/v2 >/dev/null )

echo "Validating ingress manifests contain required top-level fields..."
for f in k8s/ingress-canary-nginx.yaml k8s/ingress-version-header-nginx.yaml; do
  grep -q "^apiVersion:" "$f"
  grep -q "^kind:" "$f"
  grep -q "^metadata:" "$f"
  grep -q "^spec:" "$f"
done

echo "All manifest validations passed (offline checks)."
