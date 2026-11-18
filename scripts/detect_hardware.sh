#!/usr/bin/env bash
# Détecte le matériel et l'environnement logiciel. Aucun droit root, ne modifie rien.
# Écrit :
#   etat/profil-materiel.md  → résumé lisible (pour Claude et pour l'utilisateur)
#   etat/profil.env          → variables réutilisées par les scripts d'installation
set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ETAT="$ROOT/etat"
mkdir -p "$ETAT"
MD="$ETAT/profil-materiel.md"
ENVF="$ETAT/profil.env"

have() { command -v "$1" >/dev/null 2>&1; }
[ -x "$HOME/.local/bin/uv" ] && export PATH="$HOME/.local/bin:$PATH"

# ---------------------------------------------------------------- Système
OS_NAME=$( (. /etc/os-release 2>/dev/null && echo "${PRETTY_NAME:-inconnu}") || echo inconnu)
OS_ID=$( (. /etc/os-release 2>/dev/null && echo "${ID:-}") || true)
OS_VER=$( (. /etc/os-release 2>/dev/null && echo "${VERSION_ID:-}") || true)
KERNEL=$(uname -r)
SESSION="${XDG_SESSION_TYPE:-inconnu}"

# ---------------------------------------------------------------- CPU / RAM
CPU=$(lscpu 2>/dev/null | awk -F: '/Model name|Nom de modèle/ {sub(/^[ \t]+/,"",$2); print $2; exit}')
[ -z "$CPU" ] && CPU=$(awk -F: '/model name/ {sub(/^[ \t]+/,"",$2); print $2; exit}' /proc/cpuinfo)
THREADS=$(nproc 2>/dev/null || echo "?")
RAM_GB=$(awk '/MemTotal/ {printf "%d", ($2/1024/1024)+0.5}' /proc/meminfo)
SWAP_GB=$(awk '/SwapTotal/ {printf "%d", ($2/1024/1024)+0.5}' /proc/meminfo)
SWAP_DETAIL=$(swapon --show=NAME,TYPE,SIZE --noheadings 2>/dev/null | tr '\n' ';' | sed 's/;$//')

# ---------------------------------------------------------------- GPU
GPU_VENDOR="none"; GPU_NAME=""; VRAM_GB=0; GPU_DRIVER_OK=0; GPU_DRIVER=""; CUDA_CAP=""; ROCM_GFX=""
LSPCI_GPUS=""
have lspci && LSPCI_GPUS=$(lspci 2>/dev/null | grep -Ei 'vga|3d controller|display controller' | sed 's/^[0-9a-f:.]* //')

# NVIDIA
if have nvidia-smi && nvidia-smi -L >/dev/null 2>&1; then
  GPU_VENDOR="nvidia"; GPU_DRIVER_OK=1
  line=$(nvidia-smi --query-gpu=name,memory.total,driver_version --format=csv,noheader,nounits | head -1)
  GPU_NAME=$(echo "$line" | cut -d, -f1 | xargs)
  VRAM_MB=$(echo "$line" | cut -d, -f2 | xargs)
  GPU_DRIVER="nvidia $(echo "$line" | cut -d, -f3 | xargs)"
  VRAM_GB=$(( (VRAM_MB + 512) / 1024 ))
  CUDA_CAP=$(nvidia-smi --query-gpu=compute_cap --format=csv,noheader 2>/dev/null | head -1 | xargs || true)
elif echo "$LSPCI_GPUS" | grep -qi nvidia; then
  GPU_VENDOR="nvidia"; GPU_DRIVER_OK=0
  GPU_NAME=$(echo "$LSPCI_GPUS" | grep -i nvidia | head -1 | sed -E 's/.*\[([^]]*)\][^[]*$/\1/')
  if lsmod 2>/dev/null | grep -q '^nouveau'; then GPU_DRIVER="nouveau (pilote libre, inutilisable pour l'IA)"; else GPU_DRIVER="aucun"; fi
fi

# AMD (si pas de NVIDIA) : VRAM lue dans sysfs, pas besoin de ROCm
if [ "$GPU_VENDOR" = "none" ]; then
  best=0
  for dev in /sys/class/drm/card[0-9]*/device; do
    [ -r "$dev/vendor" ] || continue
    [ "$(cat "$dev/vendor")" = "0x1002" ] || continue
    v=0; [ -r "$dev/mem_info_vram_total" ] && v=$(cat "$dev/mem_info_vram_total")
    if [ "$v" -gt "$best" ]; then
      best=$v
      drv=$(basename "$(readlink -f "$dev/driver" 2>/dev/null)" 2>/dev/null)
      GPU_DRIVER="${drv:-inconnu}"
    fi
  done
  if [ "$best" -gt 0 ]; then
    GPU_VENDOR="amd"
    VRAM_GB=$(( (best / 1024 / 1024 + 512) / 1024 ))
    GPU_NAME=$(echo "$LSPCI_GPUS" | grep -Ei 'advanced micro|amd/ati|radeon' | head -1 | sed -E 's/.*\[([^]]*)\][^[]*$/\1/')
    [ "$GPU_DRIVER" = "amdgpu" ] && GPU_DRIVER_OK=1
    if have rocminfo; then
      ROCM_GFX=$(rocminfo 2>/dev/null | grep -o 'gfx[0-9a-f]\{3,4\}' | grep -v '^gfx000' | head -1)
    fi
  fi
fi

# Intel Arc (discret) en dernier recours
if [ "$GPU_VENDOR" = "none" ] && echo "$LSPCI_GPUS" | grep -Eqi 'intel.*(arc|dg2|battlemage)'; then
  GPU_VENDOR="intel"
  GPU_NAME=$(echo "$LSPCI_GPUS" | grep -i intel | head -1)
  GPU_DRIVER_OK=1
fi

# Palier (TIER) selon la VRAM — voir docs/materiel.md
if   [ "$GPU_VENDOR" = "none" ]; then TIER=0
elif [ "$VRAM_GB" -eq 0 ]; then TIER=-1   # GPU présent mais VRAM inconnue (pilote absent)
elif [ "$VRAM_GB" -lt 8 ];  then TIER=1
elif [ "$VRAM_GB" -lt 12 ]; then TIER=2
elif [ "$VRAM_GB" -lt 16 ]; then TIER=3
elif [ "$VRAM_GB" -lt 24 ]; then TIER=4
else TIER=5; fi

# ---------------------------------------------------------------- Secure Boot
SECURE_BOOT="inconnu"
if have mokutil; then
  sb=$(mokutil --sb-state 2>/dev/null || true)
  echo "$sb" | grep -qi enabled && SECURE_BOOT=1
  echo "$sb" | grep -qi disabled && SECURE_BOOT=0
fi
if [ "$SECURE_BOOT" = "inconnu" ]; then
  f=$(ls /sys/firmware/efi/efivars/SecureBoot-* 2>/dev/null | head -1)
  [ -n "$f" ] && SECURE_BOOT=$(od -An -t u1 "$f" 2>/dev/null | awk '{print $NF}')
fi

# ---------------------------------------------------------------- Disque
DISK_FREE_GB=$(df -BG --output=avail "$ROOT" 2>/dev/null | tail -1 | tr -dc '0-9')
DISK_FS=$(df --output=fstype "$ROOT" 2>/dev/null | tail -1 | xargs)

# ---------------------------------------------------------------- Logiciels
ver() { have "$1" && { "$@" 2>&1 | head -1; } || echo "absent"; }
PY_SYS=$(ver python3 --version)
UV_V=$(ver uv --version)
GIT_V=$(ver git --version)
LFS_V=$(have git-lfs && git lfs version 2>/dev/null | head -1 || echo absent)
FFMPEG_V="absent"; FFMPEG_X264=0; FFMPEG_NVENC=0
if have ffmpeg; then
  FFMPEG_V=$(ffmpeg -hide_banner -version 2>/dev/null | head -1 | cut -c1-60)
  encs=$(ffmpeg -hide_banner -encoders 2>/dev/null)
  echo "$encs" | grep -q libx264 && FFMPEG_X264=1
  echo "$encs" | grep -q h264_nvenc && FFMPEG_NVENC=1
fi
RPMFUSION=0; ls /etc/yum.repos.d/rpmfusion-nonfree*.repo >/dev/null 2>&1 && RPMFUSION=1
FLATPAK=0; have flatpak && FLATPAK=1
KDENLIVE=0; [ "$FLATPAK" = 1 ] && flatpak list --app 2>/dev/null | grep -qi kdenlive && KDENLIVE=1; have kdenlive && KDENLIVE=1
NVTOP=0; have nvtop && NVTOP=1
GROUPS_OK=1; [ "$GPU_VENDOR" = "amd" ] && { id -nG | grep -qw render && id -nG | grep -qw video || GROUPS_OK=0; }
CLAUDE_V=$(ver claude --version)

# Outils déjà installés dans outils/
INSTALLES=""
for d in "$ROOT"/outils/*/; do [ -d "$d/.venv" ] || [ -d "$d/.git" ] && INSTALLES+="$(basename "$d") "; done
INSTALLES="${INSTALLES:-aucun}"

# ---------------------------------------------------------------- Points d'attention
ALERTES=()
[ "$OS_ID" != "fedora" ] && ALERTES+=("Le système n'est pas Fedora ($OS_NAME) : les scripts d'install système sont écrits pour Fedora, il faudra adapter.")
if [ "$GPU_VENDOR" = "nvidia" ] && [ "$GPU_DRIVER_OK" = 0 ]; then
  ALERTES+=("Carte NVIDIA détectée mais **pilote propriétaire absent** ($GPU_DRIVER) → priorité n°1 : \`sudo bash scripts/install/00_systeme_fedora.sh\` puis redémarrage.")
  [ "$SECURE_BOOT" = 1 ] && ALERTES+=("Secure Boot activé : il faudra **enrôler la clé MOK** au redémarrage après l'installation du pilote NVIDIA (écran bleu « Enroll MOK », voir docs/fedora.md).")
fi
[ "$GPU_VENDOR" = "none" ] && ALERTES+=("Aucune carte graphique exploitable détectée : tout ce qui est image/vidéo sera très lent en local → privilégier la location de GPU ou les services en ligne (docs/options-payantes.md). Voix et face swap court restent faisables sur CPU.")
[ "$GPU_VENDOR" = "amd" ] && [ "$GROUPS_OK" = 0 ] && ALERTES+=("Carte AMD : l'utilisateur n'est pas dans les groupes \`render\` et \`video\` → le script système l'ajoute (puis se déconnecter/reconnecter).")
[ "$GPU_VENDOR" = "amd" ] && ALERTES+=("Carte AMD : on passera par ROCm. Selon le modèle de carte, il peut falloir \`HSA_OVERRIDE_GFX_VERSION\` (voir docs/fedora.md). Moins de choses marchent « du premier coup » qu'avec NVIDIA.")
[ "${RAM_GB:-0}" -lt 24 ] && ALERTES+=("RAM ${RAM_GB} Go : juste pour les gros modèles vidéo (déchargement en RAM). Activer DOCP dans le BIOS (gratuit), ajouter du swap (\`scripts/install/01_swap.sh\`), ou passer à 32 Go si on vise la vidéo en local.")
[ "${DISK_FREE_GB:-0}" -lt 100 ] && ALERTES+=("Seulement ${DISK_FREE_GB} Go libres : il en faut ~50 Go pour le minimum, 150-250 Go pour être tranquille avec les modèles vidéo.")
[ "$RPMFUSION" = 0 ] && ALERTES+=("Dépôts RPM Fusion non activés (nécessaires pour ffmpeg complet et le pilote NVIDIA) → le script système s'en occupe.")
[ "$FFMPEG_X264" = 0 ] && ALERTES+=("ffmpeg absent ou version « free » sans encodeur H.264 → le script système installe la version complète.")
[ "$UV_V" = "absent" ] && ALERTES+=("\`uv\` absent (gestionnaire Python) → installé automatiquement par les scripts d'install, sans sudo.")

# ---------------------------------------------------------------- Écriture profil.env
{
  echo "# Généré par scripts/detect_hardware.sh le $(date '+%F %T')"
  printf 'OS_ID=%q\nOS_VER=%q\n' "$OS_ID" "$OS_VER"
  printf 'GPU_VENDOR=%q\nGPU_NAME=%q\nVRAM_GB=%q\nGPU_DRIVER_OK=%q\nTIER=%q\n' "$GPU_VENDOR" "$GPU_NAME" "$VRAM_GB" "$GPU_DRIVER_OK" "$TIER"
  printf 'CUDA_CAP=%q\nROCM_GFX=%q\n' "$CUDA_CAP" "$ROCM_GFX"
  printf 'RAM_GB=%q\nDISK_FREE_GB=%q\nSECURE_BOOT=%q\n' "$RAM_GB" "$DISK_FREE_GB" "$SECURE_BOOT"
  # Préserver un éventuel réglage manuel AMD
  if [ -f "$ENVF.local" ]; then echo "# --- réglages manuels (profil.env.local)"; cat "$ENVF.local"; fi
} > "$ENVF"

# ---------------------------------------------------------------- Écriture profil-materiel.md
oui() { [ "$1" = 1 ] && echo "oui" || echo "non"; }
{
  echo "# Profil matériel"
  echo
  echo "_Détecté le $(date '+%d/%m/%Y à %H:%M') par \`scripts/detect_hardware.sh\`. Relancer le script après tout changement de matériel ou de pilote._"
  echo
  echo "| Élément | Valeur |"
  echo "|---|---|"
  echo "| Système | $OS_NAME (noyau $KERNEL, session $SESSION) |"
  echo "| CPU | $CPU ($THREADS threads) |"
  echo "| RAM | ${RAM_GB} Go — swap ${SWAP_GB} Go (${SWAP_DETAIL:-aucun}) |"
  echo "| GPU | ${GPU_NAME:-aucun} ($GPU_VENDOR) |"
  echo "| VRAM | ${VRAM_GB} Go → **palier $TIER** (voir docs/materiel.md) |"
  echo "| Pilote GPU | ${GPU_DRIVER:-—} — opérationnel : $(oui "$GPU_DRIVER_OK") |"
  [ -n "$CUDA_CAP" ] && echo "| Compute capability CUDA | $CUDA_CAP |"
  [ "$GPU_VENDOR" = "amd" ] && echo "| ROCm gfx | ${ROCM_GFX:-rocminfo absent} |"
  echo "| Secure Boot | $SECURE_BOOT (1 = activé) |"
  echo "| Disque libre (dossier du repo) | ${DISK_FREE_GB} Go ($DISK_FS) |"
  echo "| Python système | $PY_SYS |"
  echo "| uv | $UV_V |"
  echo "| git / git-lfs | $GIT_V / $LFS_V |"
  echo "| ffmpeg | $FFMPEG_V — x264 : $(oui $FFMPEG_X264), NVENC : $(oui $FFMPEG_NVENC) |"
  echo "| RPM Fusion | $(oui $RPMFUSION) |"
  echo "| Flatpak / Kdenlive | $(oui $FLATPAK) / $(oui $KDENLIVE) |"
  echo "| nvtop | $(oui $NVTOP) |"
  echo "| Claude Code | $CLAUDE_V |"
  echo "| Outils installés dans outils/ | $INSTALLES |"
  echo
  echo "## Toutes les cartes vues par lspci"
  echo
  echo '```'
  echo "${LSPCI_GPUS:-lspci absent ou aucune carte}"
  echo '```'
  echo
  echo "## Points d'attention"
  echo
  if [ ${#ALERTES[@]} -eq 0 ]; then echo "- Rien à signaler 👍"; else for a in "${ALERTES[@]}"; do echo "- $a"; done; fi
  echo
  echo "## Connu par ailleurs (relevé HWiNFO sous Windows)"
  echo
  echo "- Carte mère ASUS ROG STRIX B550-F GAMING (WI-FI), BIOS 1202 (10/2020)"
  echo "- RAM : 2 × 8 Go G.Skill F4-3200C16 tournant à 2133 MT/s → profil DOCP à activer dans le BIOS (touche Suppr au démarrage → Ai Tweaker → Ai Overclock Tuner → D.O.C.P.)"
} > "$MD"

cat "$MD"
