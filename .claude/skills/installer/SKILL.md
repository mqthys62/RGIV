---
name: installer
description: Installer, mettre à jour, réparer ou désinstaller un module (ComfyUI, FaceFusion, voix/Chatterbox, audio-separator/Whisper, Applio, Kdenlive, modèles, extensions ComfyUI).
---

# Installer / réparer un module

## Modules disponibles

| Module | Commande | Taille approx. (hors modèles) |
|---|---|---|
| Système (root, **par lui**) | `sudo bash scripts/install/00_systeme_fedora.sh` | 1-3 Go |
| Swap (root, **par lui**) | `sudo bash scripts/install/01_swap.sh` | 16 Go de disque |
| ComfyUI | `bash scripts/install/comfyui.sh` | ~6-8 Go (PyTorch inclus) |
| FaceFusion | `bash scripts/install/facefusion.sh` | ~4-6 Go + 1-2 Go de modèles |
| Chatterbox | `bash scripts/install/voix.sh chatterbox` | ~5 Go + 3 Go de modèle |
| audio-separator + Whisper | `bash scripts/install/voix.sh audio` | ~5 Go + 0,5-3 Go de modèles |
| Applio (RVC) | `bash scripts/install/applio.sh` | ~6-8 Go |

Variables utiles : `FORCE_CPU=1` (installer sans GPU), `TORCH_INDEX=<url>` (autre build PyTorch).

## Procédure

1. Vérifie l'espace disque (`df -h .`) et annonce la taille.
2. Lis le script avant de le lancer (il a peut-être besoin d'être adapté à une nouvelle version de l'outil).
3. Lance-le **en arrière-plan**, suis la sortie.
4. En cas d'erreur : lis l'erreur entière, cherche la cause (recherche web sur le message exact si besoin), corrige le script ou passe la commande à la main, puis relance. Problèmes classiques :
   - `CUDA not available` → pilote NVIDIA ? `nvidia-smi`. Mauvais index PyTorch ? `docs/fedora.md`.
   - erreur de compilation (`gcc`, `Python.h`) → paquets système manquants : le script `00_systeme_fedora.sh` a-t-il été lancé ?
   - conflit de versions → l'outil a son propre venv : on peut le supprimer (`rm -rf outils/<outil>/.venv`) et relancer.
   - `libcudnn… not found` → `scripts/lancer/env.sh` doit être utilisé (les lanceurs le font), vérifier `installer_libs_cuda_pip`.
5. **Teste** que ça marche vraiment (import + petit essai), pas juste que l'install ne plante pas.
6. Note dans `etat/journal.md` (version, problème rencontré et solution).

## Extensions ComfyUI (custom nodes)

Quand un workflow réclame des nœuds manquants :
```bash
cd outils/ComfyUI/custom_nodes && git clone --depth 1 <url>
bash ../../../scripts/lancer/py.sh ComfyUI -m pip install -r <dossier>/requirements.txt   # s'il y en a un
```
(ou via ComfyUI-Manager dans l'interface : « Install Missing Custom Nodes »). Redémarrer ComfyUI ensuite.

## Mettre à jour

Relancer le script d'install : il fait `git pull` et met à jour les dépendances. Avant une grosse session de génération la veille de l'anniversaire, **ne pas** mettre à jour (risque de casse).

## Désinstaller / libérer de la place

`du -sh outils/* outils/ComfyUI/models/*` pour voir ce qui pèse. Supprimer un outil = supprimer son dossier `outils/<nom>`. Les caches Hugging Face sont dans `~/.cache/huggingface` (souvent plusieurs Go). Toujours demander avant de supprimer.
