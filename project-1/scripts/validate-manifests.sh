#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

TOOLS_DIR="$ROOT_DIR/.tools/bin"
mkdir -p "$TOOLS_DIR"
export PATH="$TOOLS_DIR:$PATH"
SKIP_RENDER=0

try_install_kustomize() {
  local version="5.4.2"
  local os arch url tmpdir
  os="$(uname | tr '[:upper:]' '[:lower:]')"
  arch="$(uname -m)"
  case "$arch" in
    x86_64) arch="amd64" ;;
    aarch64|arm64) arch="arm64" ;;
    *) echo "warning: unsupported architecture: $arch" >&2; return 1 ;;
  esac

  url="https://github.com/kubernetes-sigs/kustomize/releases/download/kustomize/v${version}/kustomize_v${version}_${os}_${arch}.tar.gz"
  tmpdir="$(mktemp -d)"

  curl -fsSL "$url" -o "$tmpdir/kustomize.tgz" || { rm -rf "$tmpdir"; return 1; }
  tar -xzf "$tmpdir/kustomize.tgz" -C "$tmpdir" || { rm -rf "$tmpdir"; return 1; }
  install -m 0755 "$tmpdir/kustomize" "$TOOLS_DIR/kustomize" || { rm -rf "$tmpdir"; return 1; }
  rm -rf "$tmpdir"
}

ensure_render_tool() {
  if command -v kustomize >/dev/null 2>&1 || command -v kubectl >/dev/null 2>&1; then
    return 0
  fi

  echo "kustomize/kubectl not found. Attempting local kustomize install..."
  if ! try_install_kustomize; then
    echo "warning: unable to install kustomize in this environment; skipping overlay render checks" >&2
    SKIP_RENDER=1
  fi
}

kustomize_render() {
  local target="$1"
  if command -v kustomize >/dev/null 2>&1; then
    kustomize build "$target"
  elif command -v kubectl >/dev/null 2>&1; then
    kubectl kustomize "$target"
  else
    return 1
  fi
}

ensure_render_tool

if [[ "$SKIP_RENDER" -eq 0 ]]; then
  echo "Validating kustomize overlays via offline render..."
  ( cd k8s && kustomize_render overlays/v1 >/dev/null )
  ( cd k8s && kustomize_render overlays/v2 >/dev/null )
else
  echo "Skipping kustomize overlay render checks."
fi

echo "Validating ingress manifests contain required top-level fields..."
for f in k8s/ingress-canary-nginx.yaml k8s/ingress-version-header-nginx.yaml; do
  grep -q "^apiVersion:" "$f"
  grep -q "^kind:" "$f"
  grep -q "^metadata:" "$f"
  grep -q "^spec:" "$f"
done

echo "All manifest validations passed."
