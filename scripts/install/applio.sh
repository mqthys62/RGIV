#!/usr/bin/env bash
# Installe Applio (RVC) : conversion voix → voix. On enregistre SA voix en jouant le texte,
# et Applio la transforme en la voix cible (meilleure intonation que la synthèse texte→voix).
# Il faut entraîner un petit modèle sur ~5-15 min de voix propre de la personne cible (30-90 min de GPU).
#   bash scripts/install/applio.sh
source "$(dirname "$0")/lib.sh"
charger_profil
exiger_gpu_pret
assurer_uv

DIR="$OUTILS/applio"
cloner_ou_maj https://github.com/IAHispano/Applio "$DIR"
cd "$DIR"
if [ -x ./run-install.sh ] || [ -f ./run-install.sh ]; then
  info "Lancement de l'installateur officiel d'Applio…"
  bash ./run-install.sh
else
  die "run-install.sh introuvable : la procédure d'Applio a changé, voir le README du dépôt."
fi
journal "Applio installé (outils/applio)"
ok "Applio installé. Lancement : cd outils/applio && bash run-applio.sh  → http://127.0.0.1:6969"
