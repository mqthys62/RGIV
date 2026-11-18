#!/usr/bin/env bash
# Installe ComfyUI (génération d'images et de vidéos) + les extensions indispensables.
#   bash scripts/install/comfyui.sh
# Les modèles ne sont PAS téléchargés ici (trop gros) : voir scripts/comfy_templates.py et /image, /video.
source "$(dirname "$0")/lib.sh"
charger_profil
exiger_gpu_pret
assurer_uv

DIR="$OUTILS/ComfyUI"
cloner_ou_maj https://github.com/comfyanonymous/ComfyUI "$DIR"
creer_venv "$DIR" 3.12
installer_torch
info "Dépendances de ComfyUI…"
uv pip install -r "$DIR/requirements.txt"

# Extensions (custom nodes) indispensables
NODES=(
  "https://github.com/ltdrdata/ComfyUI-Manager"              # installer d'autres extensions depuis l'interface
  "https://github.com/city96/ComfyUI-GGUF"                   # modèles quantifiés GGUF (gros modèles sur petite VRAM)
  "https://github.com/Kosinkadink/ComfyUI-VideoHelperSuite"  # charger / enregistrer des vidéos
  "https://github.com/kijai/ComfyUI-KJNodes"                 # utilitaires utilisés par beaucoup de workflows vidéo
)
for url in "${NODES[@]}"; do
  name="$(basename "$url")"
  cloner_ou_maj "$url" "$DIR/custom_nodes/$name"
  [ -f "$DIR/custom_nodes/$name/requirements.txt" ] && uv pip install -r "$DIR/custom_nodes/$name/requirements.txt" || true
done
uv pip install "huggingface_hub[cli]"

mkdir -p "$ROOT/projet/sorties/comfyui"
verifier_torch
journal "ComfyUI installé ($(git -C "$DIR" rev-parse --short HEAD), GPU=$GPU_VENDOR)"
ok "ComfyUI installé. Lancement : bash scripts/lancer/comfyui.sh  → http://127.0.0.1:8188"
