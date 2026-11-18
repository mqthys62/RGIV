#!/usr/bin/env bash
# Installe les outils audio :
#   outils/chatterbox  → clonage de voix + synthèse (texte → voix de quelqu'un), multilingue dont français
#   outils/audio       → audio-separator (isoler voix / musique) + faster-whisper (transcription, sous-titres)
#
#   bash scripts/install/voix.sh            (les deux)
#   bash scripts/install/voix.sh chatterbox (un seul)
source "$(dirname "$0")/lib.sh"
charger_profil
exiger_gpu_pret
assurer_uv
CIBLES="${*:-chatterbox audio}"

installer_chatterbox() {
  local DIR="$OUTILS/chatterbox"; mkdir -p "$DIR"
  creer_venv "$DIR" 3.11
  info "Installation de Chatterbox (Resemble AI)…"
  uv pip install chatterbox-tts
  # chatterbox épingle une version de torch (build CUDA de PyPI). Pour AMD/Intel, on remet la même version
  # depuis le bon index pour avoir l'accélération GPU.
  if [ "$GPU_VENDOR" = amd ] || [ "$GPU_VENDOR" = intel ]; then
    local TV TAV
    TV=$(python -c "import torch;print(torch.__version__.split('+')[0])")
    TAV=$(python -c "import torchaudio;print(torchaudio.__version__.split('+')[0])")
    info "Réinstallation de torch $TV / torchaudio $TAV pour $GPU_VENDOR…"
    uv pip install --reinstall "torch==$TV" "torchaudio==$TAV" --index-url "$(torch_index)" \
      || warn "Pas de build $GPU_VENDOR pour torch $TV : Chatterbox tournera sur CPU (lent mais OK)."
  fi
  verifier_torch
  deactivate
  journal "Chatterbox installé (outils/chatterbox)"
}

installer_audio() {
  local DIR="$OUTILS/audio"; mkdir -p "$DIR"
  creer_venv "$DIR" 3.12
  installer_torch
  if [ "$GPU_VENDOR" = nvidia ]; then
    uv pip install "audio-separator[gpu]" faster-whisper
    installer_libs_cuda_pip
  else
    uv pip install "audio-separator[cpu]" faster-whisper
  fi
  verifier_torch
  deactivate
  journal "audio-separator + faster-whisper installés (outils/audio)"
}

for c in $CIBLES; do
  case "$c" in
    chatterbox) installer_chatterbox ;;
    audio)      installer_audio ;;
    *) warn "Cible inconnue : $c (attendu : chatterbox, audio)" ;;
  esac
done
ok "Outils voix installés. Scripts prêts dans scripts/voix/ (voir /voix)."
