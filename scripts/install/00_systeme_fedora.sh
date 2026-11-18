#!/usr/bin/env bash
# Préparation du système Fedora (paquets, ffmpeg complet, pilote GPU, Kdenlive).
#
#   À lancer TOI-MÊME dans un terminal :   sudo bash scripts/install/00_systeme_fedora.sh
#
# Options (variables d'environnement) :
#   SANS_KDENLIVE=1   ne pas installer le logiciel de montage Kdenlive
#   SANS_PILOTE=1     ne pas toucher au pilote graphique
# Le script peut être relancé sans risque.
set -euo pipefail

[ "$(id -u)" -eq 0 ] || { echo "Il faut les droits admin : sudo bash $0"; exit 1; }
REAL_USER="${SUDO_USER:-}"
FEDVER="$(rpm -E %fedora)"
REBOOT=0

etape() { printf '\n\033[1;34m=== %s ===\033[0m\n' "$*"; }

etape "1/6 Dépôts RPM Fusion (logiciels non libres : ffmpeg complet, pilote NVIDIA)"
if ! rpm -q rpmfusion-free-release rpmfusion-nonfree-release >/dev/null 2>&1; then
  dnf install -y \
    "https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-${FEDVER}.noarch.rpm" \
    "https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-${FEDVER}.noarch.rpm"
else
  echo "Déjà activés."
fi

etape "2/6 Outils de base"
dnf install -y --skip-unavailable git git-lfs gcc gcc-c++ make cmake python3-devel pciutils mokutil \
  curl wget unzip espeak-ng sox htop nvtop libsndfile portaudio-devel
[ -n "$REAL_USER" ] && sudo -u "$REAL_USER" git lfs install --skip-repo >/dev/null 2>&1 || true

etape "3/6 ffmpeg complet (avec H.264/H.265)"
if rpm -q ffmpeg-free >/dev/null 2>&1; then
  dnf swap -y ffmpeg-free ffmpeg --allowerasing
else
  dnf install -y ffmpeg
fi

etape "4/6 Pilote de la carte graphique"
GPUS="$(lspci | grep -Ei 'vga|3d controller|display controller' || true)"
echo "$GPUS"
if [ "${SANS_PILOTE:-0}" = 1 ]; then
  echo "SANS_PILOTE=1 : on ne touche pas au pilote."
elif echo "$GPUS" | grep -qi nvidia; then
  if nvidia-smi -L >/dev/null 2>&1; then
    echo "Pilote NVIDIA déjà fonctionnel."
  else
    dnf install -y akmod-nvidia xorg-x11-drv-nvidia-cuda
    SB="$(mokutil --sb-state 2>/dev/null || true)"
    if echo "$SB" | grep -qi enabled; then
      echo
      echo ">>> Secure Boot est ACTIVÉ : il faut faire signer le pilote par une clé que tu vas autoriser."
      kmodgenca -a || true
      echo ">>> Choisis un mot de passe simple (ex : 1234), tu devras le retaper UNE fois au redémarrage."
      mokutil --import /etc/pki/akmods/certs/public_key.der || echo "(clé déjà importée ou en attente)"
      echo
      echo ">>> AU REDÉMARRAGE : un écran bleu « Perform MOK management » apparaît."
      echo ">>>   Enroll MOK → Continue → Yes → tape le mot de passe → Reboot."
      echo ">>>   Si tu rates l'écran (10 s), relance ce script et redémarre à nouveau."
    fi
    echo "Compilation du module NVIDIA (quelques minutes)…"
    akmods --force || true
    for _ in $(seq 1 60); do
      modinfo -F version nvidia >/dev/null 2>&1 && break
      sleep 10
    done
    modinfo -F version nvidia >/dev/null 2>&1 && echo "Module NVIDIA compilé : $(modinfo -F version nvidia)" \
      || echo "Le module n'est pas encore prêt : attends 5 min avant de redémarrer."
    REBOOT=1
  fi
elif echo "$GPUS" | grep -Eqi 'advanced micro|amd/ati|radeon'; then
  dnf install -y rocminfo rocm-smi
  if [ -n "$REAL_USER" ]; then
    usermod -aG render,video "$REAL_USER"
    echo "$REAL_USER ajouté aux groupes render et video (effectif après déconnexion/reconnexion)."
  fi
else
  echo "Pas de carte NVIDIA/AMD détectée : rien à installer côté pilote."
fi

etape "5/6 Kdenlive (montage vidéo à la souris)"
if [ "${SANS_KDENLIVE:-0}" = 1 ]; then
  echo "Ignoré (SANS_KDENLIVE=1)."
else
  flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo
  flatpak install -y --noninteractive flathub org.kde.kdenlive || echo "Échec Kdenlive (pas grave, on pourra réessayer)."
fi

etape "6/6 Terminé"
echo "Système prêt."
if [ "$REBOOT" = 1 ]; then
  echo
  echo "⚠  REDÉMARRE le PC pour activer le pilote NVIDIA (sudo reboot)."
  echo "   Puis relance Claude dans le dossier du projet : il vérifiera que tout marche."
fi
