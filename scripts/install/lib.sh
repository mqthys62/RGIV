#!/usr/bin/env bash
# Fonctions communes aux scripts d'installation (espace utilisateur, sans sudo).
# Usage : source "$(dirname "$0")/lib.sh"

set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
OUTILS="$ROOT/outils"
mkdir -p "$OUTILS"

info() { printf '\033[1;34m▶ %s\033[0m\n' "$*"; }
ok()   { printf '\033[1;32m✔ %s\033[0m\n' "$*"; }
warn() { printf '\033[1;33m⚠ %s\033[0m\n' "$*" >&2; }
die()  { printf '\033[1;31m✖ %s\033[0m\n' "$*" >&2; exit 1; }
have() { command -v "$1" >/dev/null 2>&1; }

charger_profil() {
  [ -f "$ROOT/etat/profil.env" ] || bash "$ROOT/scripts/detect_hardware.sh" >/dev/null
  # shellcheck disable=SC1091
  . "$ROOT/etat/profil.env"
  [ "${FORCE_CPU:-0}" = 1 ] && { GPU_VENDOR=none; GPU_DRIVER_OK=0; warn "FORCE_CPU=1 : installation en mode CPU"; }
  return 0
}

assurer_uv() {
  [ -x "$HOME/.local/bin/uv" ] && export PATH="$HOME/.local/bin:$PATH"
  if ! have uv; then
    info "Installation de uv (gestionnaire Python, sans sudo)…"
    curl -LsSf https://astral.sh/uv/install.sh | sh
    export PATH="$HOME/.local/bin:$PATH"
  fi
  have uv || die "uv introuvable après installation"
}

exiger_gpu_pret() {
  if [ "$GPU_VENDOR" = nvidia ] && [ "$GPU_DRIVER_OK" != 1 ]; then
    die "Carte NVIDIA sans pilote : lance d'abord 'sudo bash scripts/install/00_systeme_fedora.sh', redémarre, puis relance 'bash scripts/detect_hardware.sh'. (Ou FORCE_CPU=1 pour installer quand même en CPU.)"
  fi
}

# Index PyTorch selon le GPU. Surchargeable : TORCH_INDEX=https://download.pytorch.org/whl/cu130 bash …
# Vérifier les index à jour sur https://pytorch.org/get-started/locally/
torch_index() {
  if [ -n "${TORCH_INDEX:-}" ]; then echo "$TORCH_INDEX"; return; fi
  case "$GPU_VENDOR" in
    nvidia) echo "https://download.pytorch.org/whl/cu128" ;;   # cu128 = OK de la RTX 20xx à la RTX 50xx
    amd)    echo "https://download.pytorch.org/whl/rocm6.4" ;;
    intel)  echo "https://download.pytorch.org/whl/xpu" ;;
    *)      echo "https://download.pytorch.org/whl/cpu" ;;
  esac
}

# cloner_ou_maj <url> <dossier>
cloner_ou_maj() {
  local url="$1" dir="$2"
  if [ -d "$dir/.git" ]; then
    info "Mise à jour de $(basename "$dir")…"
    git -C "$dir" pull --ff-only || warn "pull impossible (modifs locales ?), on garde la version actuelle"
  else
    info "Clonage de $url…"
    git clone --depth 1 "$url" "$dir"
  fi
}

# creer_venv <dossier> <version_python>  → crée <dossier>/.venv et l'active
creer_venv() {
  local dir="$1" py="${2:-3.12}"
  if [ ! -x "$dir/.venv/bin/python" ]; then
    info "Création du venv Python $py dans $dir/.venv…"
    uv venv --seed --python "$py" "$dir/.venv"
  fi
  # shellcheck disable=SC1091
  . "$dir/.venv/bin/activate"
}

# installer_torch : installe torch/torchvision/torchaudio adaptés au GPU dans le venv actif
installer_torch() {
  local idx; idx="$(torch_index)"
  info "Installation de PyTorch depuis $idx…"
  uv pip install torch torchvision torchaudio --index-url "$idx"
}

# Pour NVIDIA : bibliothèques CUDA/cuDNN en paquets pip (utilisées par onnxruntime-gpu, ctranslate2…)
installer_libs_cuda_pip() {
  [ "$GPU_VENDOR" = nvidia ] || return 0
  info "Installation des bibliothèques CUDA 12 / cuDNN 9 (pip)…"
  uv pip install nvidia-cuda-runtime-cu12 nvidia-cublas-cu12 nvidia-cudnn-cu12 nvidia-cufft-cu12 nvidia-curand-cu12 nvidia-cuda-nvrtc-cu12
}

verifier_torch() {
  python - <<'PY'
import torch
gpu = torch.cuda.is_available()
print("PyTorch", torch.__version__, "| GPU utilisable :", gpu)
if gpu:
    print("Carte :", torch.cuda.get_device_name(0))
PY
}

journal() {
  mkdir -p "$ROOT/etat"
  echo "- $(date '+%F %H:%M') — $*" >> "$ROOT/etat/journal.md"
}
