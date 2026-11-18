#!/usr/bin/env bash
# Lance ComfyUI → http://127.0.0.1:8188  (Ctrl+C pour arrêter)
# Les images/vidéos générées arrivent dans projet/sorties/comfyui/
# Arguments supplémentaires transmis à ComfyUI (ex : --lowvram, --cpu, --port 8189)
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
DIR="$ROOT/outils/ComfyUI"
[ -x "$DIR/.venv/bin/python" ] || { echo "ComfyUI n'est pas installé : bash scripts/install/comfyui.sh" >&2; exit 1; }
# shellcheck disable=SC1091
source "$ROOT/scripts/lancer/env.sh" "$DIR"
EXTRA=()
[ "${GPU_VENDOR:-none}" = none ] && EXTRA+=(--cpu)
mkdir -p "$ROOT/projet/sorties/comfyui"
cd "$DIR"
exec .venv/bin/python main.py --listen 127.0.0.1 --port 8188 \
  --output-directory "$ROOT/projet/sorties/comfyui" "${EXTRA[@]}" "$@"
