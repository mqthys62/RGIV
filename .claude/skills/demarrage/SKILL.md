---
name: demarrage
description: Premier lancement ou changement de matériel — détecte la config du PC, explique ce qui est faisable gratuitement en local, ce qui ne l'est pas, les alternatives payantes, puis installe le nécessaire. À utiliser automatiquement si etat/profil-materiel.md n'existe pas.
---

# Démarrage : diagnostic + plan

Objectif : en 10 minutes de discussion, il sait ce que son PC peut faire, ce que tu lui conseilles, et l'installation est lancée.

## 1. Détection

```bash
bash scripts/detect_hardware.sh
```

Lis `etat/profil-materiel.md`. Complète si besoin : `nvidia-smi`, `free -h`, `df -h ~`, `lsblk`.

Cas particuliers à traiter **avant** tout le reste :
- **NVIDIA sans pilote** (`GPU_DRIVER_OK=0`) : explique-lui qu'il faut installer le pilote, donne la commande `sudo bash scripts/install/00_systeme_fedora.sh` à lancer dans un autre terminal, explique l'écran bleu MOK au redémarrage (Secure Boot est activé chez lui, voir `docs/fedora.md`). Note dans le journal qu'on attend le redémarrage, et qu'à la prochaine session il faut relancer la détection.
- **Pas Fedora** : adapte les commandes (dnf → apt…) et préviens-le.
- **GPU non reconnu / VRAM inconnue** (`TIER=-1`) : demande-lui le modèle exact de sa carte, ou cherche-le (`lspci -nn`).

## 2. Explication (en langage simple, court)

Présente en 5-10 lignes max :
- sa carte graphique et sa VRAM → le palier (`docs/materiel.md`) et ce que ça veut dire concrètement ;
- la RAM 16 Go à 2133 MT/s → **DOCP à activer** (gratuit, explique comment), et si la vidéo locale est un objectif, 32 Go ou swap ;
- l'espace disque disponible.

Puis un tableau « ce que tu pourras faire » avec 3 colonnes : **Gratuit en local** / **Lent ou limité** / **Option payante conseillée (prix vérifié)**. Couvre : face swap vidéo, images, mettre sa femme dans une image, animer une photo, remplacer un personnage, clonage de voix, chanson. Vérifie les prix par une recherche web avant de les donner (`docs/options-payantes.md` sert de base).

## 3. Ses envies et son calendrier

Demande-lui (en une seule question groupée, pas un interrogatoire) :
- la **date de l'anniversaire** (pour planifier : il faut du temps pour installer, générer, rater, recommencer) ;
- les 2-3 premiers montages qu'il a en tête (ou propose le skill `/idees` s'il n'en a pas) ;
- s'il est prêt à mettre quelques euros, et combien max.

Crée `projet/idees.md` s'il n'existe pas (modèle : section par montage avec Statut / Entrées nécessaires / Outils / Notes).

## 4. Installation ciblée

Ordre conseillé (ne fais que ce qui sert à ses premières idées) :

1. `sudo bash scripts/install/00_systeme_fedora.sh` — **par lui**, une fois (ffmpeg complet, pilote, Kdenlive). Si RAM ≤ 16 Go et qu'il vise la vidéo : `sudo bash scripts/install/01_swap.sh`.
2. `bash scripts/install/facefusion.sh` — presque toujours utile, léger, effet « waouh » immédiat.
3. `bash scripts/install/voix.sh` — si faux audios.
4. `bash scripts/install/comfyui.sh` — images/vidéos. Puis les modèles adaptés à son palier (skills `/image`, `/video`).
5. `bash scripts/install/applio.sh` — seulement s'il veut de la conversion voix→voix.

Lance les installs en arrière-plan, surveille, corrige si ça plante. Annonce la taille des téléchargements.

## 5. Premier test « waouh »

Dès qu'un outil marche, propose un **mini test** avec ses fichiers (ex : son visage sur une scène de film de 5 s) pour valider la chaîne et le motiver.

## 6. Journal

Écris dans `etat/journal.md` : config détectée (résumé), décisions (budget, date, priorités), ce qui est installé, prochaine étape.
