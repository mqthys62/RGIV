# Catalogue des outils locaux (gratuits)

> Rédigé en novembre 2026. Les modèles évoluent très vite : **avant d'installer, vérifie par une recherche web s'il existe mieux ou plus léger**, et privilégie ce qui a un template officiel ComfyUI (`python3 scripts/comfy_templates.py list`).

## Les briques principales

| Outil | Rôle | Install | Lancer | Doc |
|---|---|---|---|---|
| **ComfyUI** | Moteur images + vidéos (nœuds), avec templates officiels prêts à l'emploi | `scripts/install/comfyui.sh` | `scripts/lancer/comfyui.sh` → :8188 | docs.comfy.org |
| **FaceFusion** | Face swap photo/vidéo, amélioration du visage, synchro labiale | `scripts/install/facefusion.sh` | `scripts/lancer/facefusion.sh` → :7860 | docs.facefusion.io |
| **Chatterbox** (multilingue) | Texte → voix clonée (10-30 s de référence), français OK | `scripts/install/voix.sh chatterbox` | `scripts/voix/tts_clone.py` | github.com/resemble-ai/chatterbox |
| **audio-separator** | Isoler voix / instruments (modèles UVR, Roformer) | `scripts/install/voix.sh audio` | `scripts/voix/separer.sh` | github.com/nomadkaraoke/python-audio-separator |
| **faster-whisper** | Transcription, sous-titres | `scripts/install/voix.sh audio` | `scripts/voix/transcrire.py` | github.com/SYSTRAN/faster-whisper |
| **Applio** (RVC) | Voix → voix (on joue le texte, ça sort avec la voix cible), entraînement de modèles de voix | `scripts/install/applio.sh` | `outils/applio/run-applio.sh` → :6969 | docs.applio.org |
| **ffmpeg** | Découpe, assemblage, mixage, sous-titres, export | `00_systeme_fedora.sh` | ligne de commande | — |
| **Kdenlive** | Montage à la souris pour lui | `00_systeme_fedora.sh` (Flatpak) | menu des applications | — |

## Modèles d'image (dans ComfyUI)

| Modèle | Points forts | VRAM conseillée | Remarque |
|---|---|---|---|
| **Z-Image Turbo** (Alibaba, 6B) | Photo-réaliste, très rapide (8 étapes), bon avec le texte | 8-12 Go (GGUF en dessous) | Excellent premier choix palier 2-3 |
| **SDXL** + checkpoints communautaires (Juggernaut XL, RealVisXL…) | Léger, énorme écosystème (LoRA, IP-Adapter, InstantID) | 6-8 Go | Le plus sûr sur petite carte |
| **FLUX.1 dev / schnell / Krea** | Très bonne qualité, suit bien les prompts | 12 Go+ (GGUF Q4 dès 8 Go) | dev = licence non commerciale (OK ici), page HF à accepter |
| **Qwen-Image** | Très bon en texte dans l'image (affiches, faux magazines) | 16 Go+ (GGUF dès 10-12 Go) | — |
| **Qwen-Image-Edit** / **FLUX.1 Kontext** | **Édition par instruction** : « mets cette personne en tenue de pirate sur un bateau », changer le décor, garder le visage | 12-16 Go+ en GGUF | Parfait pour mettre la femme dans des scènes à partir d'UNE photo |
| **LoRA personnalisé** (ai-toolkit, FluxGym, kohya) | Ressemblance maximale : on entraîne le modèle sur 15-30 photos de la personne | 12-24 Go | Ou dans le cloud pour quelques € |

Astuce la plus rentable : **générer une scène avec n'importe quel modèle, puis face swap FaceFusion** dessus. Marche sur toutes les configs.

Restauration / bonus : **CodeFormer / GFPGAN** (visages, inclus dans FaceFusion), **Real-ESRGAN / 4x-UltraSharp** (agrandir), **DDColor** (coloriser des vieilles photos d'enfance), **rembg / BiRefNet** (détourer).

## Modèles vidéo (dans ComfyUI)

| Modèle | Usage | VRAM | Remarque |
|---|---|---|---|
| **Wan 2.2 TI2V 5B** | Texte→vidéo et image→vidéo, 720p | 8-12 Go | Bon compromis palier 2 |
| **Wan 2.2 14B (T2V / I2V)** | Meilleure qualité open source | 12 Go+ en GGUF, 16-24 Go en fp8 | Avec LoRA **lightx2v** (4-8 étapes) : 5-10× plus rapide |
| **Wan 2.2 Animate 14B** | **Remplacer un personnage dans une vidéo** par une personne d'une photo (corps + visage + mouvements), ou animer une photo avec les mouvements d'une vidéo | 16-24 Go+ | Idéal pour « mettre sa femme à la place de l'actrice ». Sinon GPU loué |
| **Wan VACE** | Édition vidéo : remplacer un objet, prolonger, restyler | 12 Go+ GGUF | — |
| **LTX-Video / LTX-2** | Rapide, LTX-2 génère aussi l'audio | 8-16 Go | Qualité un cran en dessous de Wan selon les cas |
| **HunyuanVideo 1.5** | Très bonne qualité | 12-16 Go+ | — |
| **FramePack** | Image→vidéo longue, très économe | 6 Go+ | Outil séparé (github.com/lllyasviel/FramePack) ou nœuds ComfyUI |
| **LivePortrait** | Faire bouger/grimacer un visage de photo en copiant une vidéo de lui | 4-6 Go | Hyper marrant, léger (nœuds ComfyUI) |
| **InfiniteTalk / Wan S2V** | Photo + audio → la personne parle | 16 Go+ | Lourd ; sinon cloud |
| **RIFE / FILM** | Interpolation (fluidifier 16 → 32 ips) | léger | Nœuds ComfyUI-Frame-Interpolation |

Taille typique des téléchargements : Wan 2.2 5B ≈ 10 Go (avec encodeur texte et VAE) · Wan 14B GGUF Q4 ≈ 10 Go par modèle (il y en a deux : high noise + low noise) + 7 Go d'encodeur · Flux dev fp8 ≈ 17 Go · Z-Image Turbo ≈ 12-20 Go selon précision.

## Lip sync (faire coller les lèvres à un nouvel audio)

| Outil | VRAM | Remarque |
|---|---|---|
| **FaceFusion `lip_syncer`** | faible | Déjà installé avec FaceFusion. Qualité correcte, idéal pour des blagues courtes |
| **LatentSync** (ByteDance) | 8 Go (v1.5) à 18 Go (v1.6) | Meilleure qualité, installation à part |
| **MuseTalk** | 4-6 Go | Rapide |

## Voix

| Outil | Ce qu'il faut | Qualité FR | Usage |
|---|---|---|---|
| **Chatterbox multilingue** | 10-30 s de voix propre | Bonne | Faire dire un texte (zéro entraînement) |
| **XTTS-v2** (paquet `coqui-tts`) | 6-30 s | Bonne | Alternative si Chatterbox rend mal une voix |
| **F5-TTS** (+ finetune français communautaire) | 10 s | Bonne | Alternative |
| **Applio / RVC** | 5-15 min de voix propre pour entraîner | Excellente (garde ton intonation) | Voix→voix : il joue la scène, ça sort avec la voix cible. Le top pour l'humour |
| **Seed-VC** | 3-30 s, sans entraînement | Bonne | Voix→voix sans entraîner |
| **ACE-Step** | — | Paroles FR possibles | Générer une chanson complète en local (8 Go+) |

Pour une voix de référence propre : extraire l'audio d'une vidéo, `scripts/voix/separer.sh` pour retirer musique/bruit, couper 10-30 s où la personne parle seule et clairement (`ffmpeg -ss 00:01:12 -t 20 -i voix.wav ref.wav`).
