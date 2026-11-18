#!/usr/bin/env bash
# Ajoute un fichier d'échange (swap) sur disque pour éviter les plantages « mémoire pleine »
# quand un gros modèle déborde de la RAM (utile avec 16 Go de RAM).
#
#   sudo bash scripts/install/01_swap.sh          (16 Go par défaut)
#   sudo TAILLE_GO=32 bash scripts/install/01_swap.sh
#
# Fedora a déjà un petit swap en RAM compressée (zram) ; celui-ci s'y ajoute, avec une priorité plus basse.
set -euo pipefail
[ "$(id -u)" -eq 0 ] || { echo "Il faut les droits admin : sudo bash $0"; exit 1; }
TAILLE="${TAILLE_GO:-16}"
FS="$(findmnt -no FSTYPE /)"

if swapon --show=NAME --noheadings | grep -q '/var/swap/swapfile\|/swapfile'; then
  echo "Un fichier de swap est déjà actif :"; swapon --show; exit 0
fi

if [ "$FS" = btrfs ]; then
  SWAPF=/var/swap/swapfile
  [ -d /var/swap ] || btrfs subvolume create /var/swap
  btrfs filesystem mkswapfile --size "${TAILLE}g" "$SWAPF"
else
  SWAPF=/swapfile
  fallocate -l "${TAILLE}G" "$SWAPF"
  chmod 600 "$SWAPF"
  mkswap "$SWAPF"
fi
# Contexte SELinux correct pour un swapfile
restorecon "$SWAPF" 2>/dev/null || true
swapon --priority 10 "$SWAPF"
grep -q "$SWAPF" /etc/fstab || echo "$SWAPF none swap defaults,nofail,pri=10 0 0" >> /etc/fstab
echo "Swap de ${TAILLE} Go ajouté :"
swapon --show
