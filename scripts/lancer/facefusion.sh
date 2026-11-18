#!/usr/bin/env bash
# Lance FaceFusion.
#   bash scripts/lancer/facefusion.sh                 → interface web http://127.0.0.1:7860
#   bash scripts/lancer/facefusion.sh headless-run …  → mode ligne de commande (utilisé par Claude)
#   bash scripts/lancer/facefusion.sh headless-run --help
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
DIR="$ROOT/outils/facefusion"
[ -x "$DIR/.venv/bin/python" ] || { echo "FaceFusion n'est pas installé : bash scripts/install/facefusion.sh" >&2; exit 1; }
# shellcheck disable=SC1091
source "$ROOT/scripts/lancer/env.sh" "$DIR"
export PATH="$DIR/.venv/bin:$PATH"
cd "$DIR"
if [ $# -eq 0 ]; then
  exec .venv/bin/python facefusion.py run --open-browser
else
  exec .venv/bin/python facefusion.py "$@"
fi
