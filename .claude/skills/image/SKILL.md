---
name: image
description: Générer ou modifier des images (portraits fantaisistes, affiches, fausses couvertures, scènes) avec ComfyUI en local, y compris mettre une vraie personne dans l'image (face swap, édition par référence, LoRA). Choisit le modèle selon la VRAM.
---

# Images

## 0. Préparer

- ComfyUI installé et lancé en arrière-plan : `bash scripts/lancer/comfyui.sh` (attendre « To see the GUI go to: http://127.0.0.1:8188 »).
- Lis `etat/profil.env` (TIER, VRAM_GB) et choisis le modèle (`docs/outils.md`). Fais une recherche web rapide « best ComfyUI image model <VRAM> GB » pour voir s'il y a mieux que la liste.

## 1. Obtenir un modèle et un workflow qui marchent

**Méthode fiable : les templates officiels.**
```bash
python3 scripts/comfy_templates.py list               # repérer ex : z_image, flux, qwen_image, sdxl…
python3 scripts/comfy_templates.py models <template>  # fichiers nécessaires + tailles
python3 scripts/comfy_templates.py download <template>
```
Petite VRAM : remplacer le modèle principal par sa version **GGUF** (repos `city96/…-gguf`, `QuantStack/…`, `unsloth/…` sur Hugging Face, à vérifier) dans `models/unet/` ou `models/diffusion_models/`, et utiliser le nœud « Unet Loader (GGUF) » à la place du chargeur standard.

Ensuite, pour piloter depuis le terminal, il faut le workflow **au format API** :
- soit il ouvre le template dans l'interface (Workflow → Browse Templates), clique Run une fois pour valider, puis **Workflow → Export (API)** → enregistrer dans `workflows/<nom>.json` ;
- soit tu l'écris toi-même au format API (cas simples : `workflows/txt2img_checkpoint.json` est un exemple pour les checkpoints SDXL/SD1.5 tout-en-un).

Lancer :
```bash
python3 scripts/comfy_run.py workflows/<nom>.json --list-nodes      # repérer les ids des nœuds
python3 scripts/comfy_run.py workflows/<nom>.json \
  --set 6.text="portrait of a woman as an egyptian queen, golden jewelry, cinematic lighting" \
  --set 3.seed=123 --out projet/sorties/2026-12-01_reine
```

## 2. Prompts

- En **anglais** pour la plupart des modèles (Qwen-Image et Z-Image comprennent aussi le français, mais l'anglais reste plus fiable).
- Décris : sujet, tenue, décor, lumière, style photo/ciné, cadrage. Pour faciliter un face swap ensuite : **visage de face ou de 3/4, assez grand dans l'image, bien éclairé**.
- Fais 4 variantes (seeds différentes), regarde-les avec Read, garde les meilleures et propose-les-lui.

## 3. Mettre une vraie personne dans l'image — 3 méthodes

1. **Générer puis face swap** (marche partout, recommandé) : génère la scène avec une personne de même genre/âge/coiffure approximative, puis `/faceswap` avec ses photos (+ `face_enhancer`).
2. **Édition par référence** (Qwen-Image-Edit, FLUX.1 Kontext, palier 3+ en GGUF) : on donne SA photo + une instruction (« make her a pirate captain on a ship deck, keep her face ») → garde visage et cheveux. Templates officiels disponibles.
3. **LoRA** (ressemblance maximale, sous tous les angles) : 15-30 photos variées → entraînement (ai-toolkit / FluxGym localement si ≥ 16 Go de VRAM, sinon GPU loué ou fal.ai, quelques €). À réserver si elle apparaît dans beaucoup de montages.

## 4. Texte dans l'image (affiches, magazines, céréales)

Qwen-Image ou Z-Image écrivent bien le texte. Sinon : générer sans texte et ajouter le texte avec ffmpeg/ImageMagick ou dans Kdenlive (rendu parfait garanti).

## 5. Après

Upscale si besoin (nœud upscale avec 4x-UltraSharp / Real-ESRGAN). Range les meilleures dans `projet/sorties/<date>_<nom>/`, note le prompt + seed + modèle dans `projet/idees.md`.
