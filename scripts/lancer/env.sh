#!/usr/bin/env bash
# Variables d'environnement GPU communes. À sourcer : source scripts/lancer/env.sh <dossier_outil>
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
_OUTIL_DIR="${1:-}"
# shellcheck disable=SC1091
[ -f "$ROOT/etat/profil.env" ] && . "$ROOT/etat/profil.env"

# AMD : certaines cartes grand public ont besoin de se faire passer pour un modèle supporté par ROCm.
# À définir dans etat/profil.env.local (ex : HSA_OVERRIDE_GFX_VERSION=10.3.0 pour RX 6000, 11.0.0 pour RX 7000).
[ -n "${HSA_OVERRIDE_GFX_VERSION:-}" ] && export HSA_OVERRIDE_GFX_VERSION

# Moins de fragmentation mémoire GPU
export PYTORCH_CUDA_ALLOC_CONF="${PYTORCH_CUDA_ALLOC_CONF:-expandable_segments:True}"
export PYTORCH_HIP_ALLOC_CONF="${PYTORCH_HIP_ALLOC_CONF:-expandable_segments:True}"

# NVIDIA : rendre visibles les bibliothèques CUDA/cuDNN installées en paquets pip dans le venv
if [ -n "$_OUTIL_DIR" ] && [ -d "$_OUTIL_DIR/.venv" ]; then
  _libs=$(find "$_OUTIL_DIR/.venv/lib" -maxdepth 5 -type d -path '*site-packages/nvidia/*/lib' 2>/dev/null | tr '\n' ':')
  [ -n "$_libs" ] && export LD_LIBRARY_PATH="${_libs}${LD_LIBRARY_PATH:-}"
fi
unset _libs _OUTIL_DIR
