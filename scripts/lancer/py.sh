#!/usr/bin/env bash
# Lance le Python du venv d'un outil, avec les bonnes variables GPU.
#   bash scripts/lancer/py.sh <outil> [arguments python…]
# Exemples :
#   bash scripts/lancer/py.sh chatterbox scripts/voix/tts_clone.py --ref … --texte "…"
#   bash scripts/lancer/py.sh audio -m audio_separator.utils.cli --help
#   bash scripts/lancer/py.sh facefusion -c "import onnxruntime; print(onnxruntime.get_available_providers())"
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
OUTIL="${1:?usage: py.sh <outil> [args…]  (outils disponibles : $(ls "$ROOT/outils" 2>/dev/null | tr '\n' ' '))}"
shift
DIR="$ROOT/outils/$OUTIL"
PY="$DIR/.venv/bin/python"
[ -x "$PY" ] || { echo "Pas de venv pour '$OUTIL' ($PY). Installe-le d'abord (scripts/install/)." >&2; exit 1; }
# shellcheck disable=SC1091
source "$ROOT/scripts/lancer/env.sh" "$DIR"
export PATH="$DIR/.venv/bin:$PATH"
exec "$PY" "$@"
