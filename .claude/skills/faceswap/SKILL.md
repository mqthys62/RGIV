---
name: faceswap
description: Mettre le visage d'une personne (sa femme, lui, un proche) dans une photo ou un extrait de film, avec FaceFusion, en local. Aussi l'amélioration de visage et la synchro labiale sur un nouvel audio.
---

# Face swap avec FaceFusion

Prérequis : `outils/facefusion` installé (`bash scripts/install/facefusion.sh`). Si ComfyUI tourne et que la VRAM est ≤ 12 Go, l'arrêter d'abord.

## Entrées

- **Source** (le visage à mettre) : 1 à 5 photos nettes de la personne, visage de face ou de 3/4, bien éclairé, sans lunettes de soleil ni main devant. Plusieurs photos = meilleure ressemblance (`--source-paths a.jpg b.jpg c.jpg`).
- **Cible** : l'image ou l'extrait vidéo. Idéalement court (5-60 s) : découpe-le d'abord avec ffmpeg (`/montage`).

Regarde les photos source avec l'outil Read : si elles sont floues, trop petites ou de profil, dis-le et demande-en d'autres.

## Commande (vérifie les options avec `bash scripts/lancer/facefusion.sh headless-run --help`, elles changent selon les versions)

```bash
bash scripts/lancer/facefusion.sh headless-run \
  --source-paths "$ROOT/projet/entrees/photos/julie_1.jpg" "$ROOT/projet/entrees/photos/julie_2.jpg" \
  --target-path "$ROOT/projet/sorties/2026-12-01_titanic/extrait.mp4" \
  --output-path "$ROOT/projet/sorties/2026-12-01_titanic/titanic_julie.mp4" \
  --processors face_swapper face_enhancer \
  --face-swapper-model hyperswap_1a_256 \
  --face-enhancer-model gfpgan_1.4 --face-enhancer-blend 60 \
  --face-selector-mode reference --reference-face-position 0 \
  --execution-providers cuda \
  --output-video-quality 90
```

(chemins **absolus** obligatoires : le lanceur se place dans `outils/facefusion`.)

- `--execution-providers` : `cuda` (NVIDIA), `rocm` ou `migraphx` (AMD), `openvino` (Intel), `cpu`.
- Modèles de swap : `hyperswap_1a_256` / `hyperswap_1b_256` (récents, nets), `inswapper_128_fp16` (classique, robuste), `simswap_unofficial_512`, `ghost_*`… Si le résultat ne ressemble pas assez, en essayer un autre.
- **Choisir quel visage remplacer** quand il y a plusieurs personnes à l'écran : `--face-selector-mode reference` + `--reference-face-position N` (0 = le plus à gauche / le plus grand selon `--face-selector-order`), ou `--reference-frame-number` pour prendre la référence à une image précise. `many` = remplacer tous les visages. Pour viser juste, extrais une image de l'extrait (`ffmpeg -ss 3 -i extrait.mp4 -frames:v 1 frame.jpg`), regarde-la, et déduis la position.
- `face_enhancer` améliore le rendu (plus net) ; `--face-enhancer-blend` 40-80 pour rester naturel.
- Plusieurs personnes différentes dans la même vidéo : faire une passe par personne (sortie de la passe 1 = cible de la passe 2).
- Pour aller vite pendant les essais : `--trim-frame-start 0 --trim-frame-end 75` (3 s) avant de lancer tout l'extrait.

## Synchro labiale (faire parler la personne sur un nouvel audio)

```bash
bash scripts/lancer/facefusion.sh headless-run \
  --source-paths "$ROOT/…/nouveau_dialogue.wav" \
  --target-path "$ROOT/…/titanic_julie.mp4" \
  --output-path "$ROOT/…/titanic_julie_lipsync.mp4" \
  --processors lip_syncer --execution-providers cuda
```
L'audio doit avoir la même durée que le passage vidéo. Ensuite remixer avec la musique d'origine (`/montage`).

## Vérification

Extrais 3-4 images de la vidéo produite (début, milieu, fin, un moment de profil) et regarde-les : visage bien placé ? clignotement ? mauvaise personne remplacée ? Corrige avant de lui annoncer que c'est prêt. Donne-lui la commande pour regarder : `xdg-open <fichier>`.

## Limites à expliquer simplement

- Visage de profil complet, très petit, ou masqué → rendu moins bon (le swap peut « sauter »). Choisir des extraits où le visage est bien visible.
- Seul le visage change : cheveux, corps, tenue restent ceux de l'acteur/actrice. Pour un remplacement complet → Wan 2.2 Animate (`/video`, 16-24 Go de VRAM ou GPU loué).
