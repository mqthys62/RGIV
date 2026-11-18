#!/usr/bin/env bash
# Installe FaceFusion (face swap photo/vidéo, amélioration de visage, synchro labiale).
#   bash scripts/install/facefusion.sh
source "$(dirname "$0")/lib.sh"
charger_profil
exiger_gpu_pret
assurer_uv

DIR="$OUTILS/facefusion"
cloner_ou_maj https://github.com/facefusion/facefusion "$DIR"
creer_venv "$DIR" 3.12

case "$GPU_VENDOR" in
  nvidia) ORT=cuda ;;
  amd)    ORT=rocm ;;
  intel)  ORT=openvino ;;
  *)      ORT=default ;;
esac
info "Installation de FaceFusion (onnxruntime : $ORT)…"
cd "$DIR"
python install.py --onnxruntime "$ORT" --skip-conda
installer_libs_cuda_pip

info "Vérification des fournisseurs d'exécution onnxruntime…"
bash "$ROOT/scripts/lancer/py.sh" facefusion -c "import onnxruntime as o; print('Providers :', o.get_available_providers())"

journal "FaceFusion installé ($(git -C "$DIR" describe --tags --always 2>/dev/null), onnxruntime=$ORT)"
ok "FaceFusion installé. Interface : bash scripts/lancer/facefusion.sh  → http://127.0.0.1:7860"
ok "Les modèles (≈1-2 Go) se téléchargent tout seuls au premier usage."
