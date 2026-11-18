---
name: video
description: Générer des vidéos (texte→vidéo, image→vidéo, animer une photo, remplacer un personnage dans un extrait) avec ComfyUI (Wan 2.2, LTX, Hunyuan, FramePack, LivePortrait) ou, si le PC ne suit pas, via GPU loué ou service en ligne.
---

# Vidéo générée

## 0. Choisir l'approche selon le palier (`etat/profil.env`) — vérifier les nouveautés par recherche web

| Besoin | Palier 0-1 | Palier 2 (8-11 Go) | Palier 3 (12-15 Go) | Palier 4-5 (16 Go+) |
|---|---|---|---|---|
| Animer une photo (image→vidéo) | Kling/Hailuo (crédits gratuits) ou GPU loué | Wan 2.2 TI2V 5B, LTX, FramePack | Wan 2.2 I2V 14B GGUF + lightx2v | Wan 2.2 I2V 14B fp8 |
| Faire grimacer / parler un visage de photo | LivePortrait (léger) | LivePortrait | LivePortrait, InfiniteTalk (lent) | InfiniteTalk, Wan S2V |
| Remplacer un personnage d'un extrait | FaceFusion (visage seul) | FaceFusion | FaceFusion ; Wan Animate GGUF (très lent) | **Wan 2.2 Animate** |
| Texte→vidéo | cloud | Wan 5B / LTX | Wan 14B GGUF | Wan 14B / Hunyuan 1.5 |

Rappel : avec 16 Go de RAM, les modèles 14B sont serrés → swap activé (`01_swap.sh`) et un seul outil lourd à la fois. Sinon, **GPU loué** (`docs/options-payantes.md`) : 1-3 € pour une soirée de rendus.

## 1. Modèles et workflows

```bash
python3 scripts/comfy_templates.py list wan      # aussi : ltx, hunyuan, animate, vace, s2v…
python3 scripts/comfy_templates.py models <template>
python3 scripts/comfy_templates.py download <template>
```
Annonce les tailles (souvent 15-40 Go par famille). Pour petite VRAM : versions GGUF (ex : `QuantStack/Wan2.2-I2V-A14B-GGUF`, à vérifier) + LoRA lightx2v 4 étapes (repos `Kijai/WanVideo_comfy` / `lightx2v/…`, à vérifier) pour diviser le temps de calcul.

Workflow API : il l'ouvre dans l'interface, valide un rendu, **Export (API)** → `workflows/`. Puis tu enchaînes les variantes avec `scripts/comfy_run.py` (timeout long, en arrière-plan).

## 2. Bonnes pratiques

- **Tester petit** : 480p, 2-3 s (33-49 images), peu d'étapes. Valider le mouvement, puis monter en résolution/durée.
- Image→vidéo : l'image de départ fait tout. Visage net et grand, cadrage déjà « cinéma ». Combo gagnant : image générée + face swap (`/image`, `/faceswap`) → animée.
- Prompt de mouvement simple et précis (en anglais) : « she turns her head, smiles at the camera and raises a glass of champagne, slow camera push-in ». Un seul geste par clip.
- Les visages peuvent dériver pendant l'animation : repasser un **face swap FaceFusion sur la vidéo générée** pour retrouver la ressemblance. Très efficace.
- Clips de 5 s → assembler au montage. Fluidifier avec RIFE (interpolation) et agrandir avec un upscaler si besoin.
- Vérifie le résultat : extrais quelques images avec ffmpeg et regarde-les avant de lui présenter.

## 3. Remplacer un personnage complet (Wan 2.2 Animate)

Entrées : l'extrait vidéo (court, 3-10 s, personnage bien visible) + une photo en pied de la personne. Le modèle reproduit les mouvements de l'acteur avec l'apparence de la personne. Mode « replace » (dans la scène d'origine) ou « animate » (sa photo qui bouge comme l'acteur). Lourd : 16-24 Go+ de VRAM, sinon GPU loué. Toujours proposer l'alternative FaceFusion (visage seul), plus simple et souvent suffisante pour l'effet comique.

## 4. Option cloud clé en main

Si le PC ne suit pas ou s'il manque de temps : Kling / Hailuo (crédits gratuits quotidiens), Veo, ou fal.ai à l'usage. Aide-le à rédiger le prompt et à préparer l'image de départ en local. Vérifie les prix actuels avant d'en parler.
