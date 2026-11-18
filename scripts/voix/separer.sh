#!/usr/bin/env bash
# Sépare la voix et le reste (musique, bruitages) d'un audio ou d'une vidéo.
#   bash scripts/voix/separer.sh projet/entrees/videos/extrait.mp4 [dossier_sortie]
# → <nom>_(Vocals)….wav  et  <nom>_(Instrumental)….wav
# Usages : 1) obtenir une voix propre pour le clonage ; 2) garder musique/bruitages d'un extrait de film
#          et remplacer le dialogue par un faux.
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
IN="${1:?usage: separer.sh <fichier audio/vidéo> [dossier_sortie]}"
OUT="${2:-$ROOT/projet/sorties/separation}"
mkdir -p "$OUT"
TMP="$(mktemp -d)"; trap 'rm -rf "$TMP"' EXIT
NOM="$(basename "${IN%.*}")"
# Extraire l'audio en WAV (marche aussi pour une vidéo)
ffmpeg -hide_banner -loglevel error -y -i "$IN" -vn -ac 2 -ar 44100 "$TMP/$NOM.wav"
# Modèle par défaut : un MelBand/BS-Roformer de séparation voix (excellente qualité). Liste : --list_models
MODELE="${MODELE:-model_bs_roformer_ep_317_sdr_12.9755.ckpt}"
source "$ROOT/scripts/lancer/env.sh" "$ROOT/outils/audio"
"$ROOT/outils/audio/.venv/bin/audio-separator" "$TMP/$NOM.wav" \
  --model_filename "$MODELE" --output_dir "$OUT" --output_format WAV \
  --model_file_dir "$ROOT/outils/audio/modeles"
ls -1 "$OUT" | grep -F "$NOM" | sed "s|^|→ $OUT/|"
