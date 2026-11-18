# Matériel : ce qu'on peut faire selon la config

## Le PC connu (relevé HWiNFO sous Windows, novembre 2026)

| Composant | Modèle | Verdict |
|---|---|---|
| CPU | AMD Ryzen 7 5800X, 8 cœurs / 16 threads, jusqu'à 4,85 GHz | Très bien. Pas un frein. |
| Carte mère | ASUS ROG STRIX B550-F GAMING (WI-FI), PCIe 4.0, 4 slots RAM (128 Go max) | Très bien, évolutive. |
| BIOS | 1202 du 21/10/2020 | Ancien mais OK. Mise à jour pas nécessaire pour ce projet. |
| RAM | 16 Go = 2 × 8 Go G.Skill F4-3200C16, **à 2133 MT/s** (slots A2 + B2) | **Le point faible.** Voir ci-dessous. |
| Secure Boot | Activé | Une étape en plus pour le pilote NVIDIA (voir `fedora.md`). |
| Carte graphique | **Non relevée** | **C'est elle qui décide de presque tout.** `scripts/detect_hardware.sh` la détecte. |

### La RAM : deux actions possibles

1. **Gratuit, 2 minutes — activer DOCP** : les barrettes sont prévues pour 3200 MT/s mais tournent à 2133. Au démarrage, touche **Suppr** → BIOS ASUS → touche **F7** (mode avancé) → **Ai Tweaker** → **Ai Overclock Tuner** → **D.O.C.P.** (choisir le profil 3200) → **F10** pour sauver. Si le PC ne redémarre pas (rare), il revient tout seul aux réglages d'avant après quelques tentatives.
2. **Payant — passer à 32 Go** : 2 barrettes supplémentaires de 8 Go identiques (F4-3200C16-8GVKB) dans les slots A1 et B1, ou un kit 2 × 16 Go. Utile **surtout pour la vidéo en local** (Wan 14B, Hunyuan…), qui décharge une partie du modèle en RAM. Les prix de la DDR4 ont beaucoup bougé en 2025-2026 : vérifier les prix du moment avant de conseiller.
3. En attendant : **ajouter du swap** (`sudo bash scripts/install/01_swap.sh`) évite les plantages « plus de mémoire » (en échange d'un peu de lenteur).

## Paliers selon la VRAM (mémoire de la carte graphique)

Le script calcule `TIER` dans `etat/profil.env`. NVIDIA = le plus simple. AMD = possible via ROCm mais plus de bricolage (et certains outils marchent moins bien). Sans GPU = cloud pour l'image/vidéo.

| Palier | VRAM | Exemples de cartes | Images | Vidéo générée | Face swap vidéo | Voix |
|---|---|---|---|---|---|---|
| 0 | aucune | — | SDXL Turbo sur CPU (1-3 min/image) → plutôt cloud | ✖ → cloud | FaceFusion CPU : OK pour des extraits courts (~1 min de vidéo = 15-40 min) | ✔ CPU, lent mais OK |
| 1 | < 8 Go | GTX 1660, RTX 2060 6 Go, RX 5600 | SDXL en `--lowvram`, Z-Image/Flux en GGUF Q3-Q4 (lent) | FramePack (image→vidéo) à la limite, sinon cloud | ✔ | ✔ |
| 2 | 8-11 Go | RTX 3060 Ti, 3070, 4060, 2080, RX 6600/6650, RX 7600 | SDXL ✔✔, Z-Image Turbo ✔, Flux/Qwen en GGUF Q4-Q5 ✔ | Wan 2.2 5B (720p court), LTX-Video, FramePack ✔ ; Wan 14B en GGUF très lent | ✔✔ | ✔✔ |
| 3 | 12-15 Go | RTX 3060 12 Go, 4070, 4070 Super, 5070, RX 6700 XT | Flux / Qwen-Image / Qwen-Image-Edit en GGUF Q5-Q8 ✔ | Wan 2.2 14B en GGUF + LoRA « lightx2v » 4 étapes ✔ (quelques min/clip) | ✔✔ | ✔✔ |
| 4 | 16-23 Go | RTX 4060 Ti 16, 4070 Ti Super, 4080, 5070 Ti, 5080, RX 6800/6900, RX 7800 XT, RX 9070 | Tout, en fp8 ✔✔ ; entraînement de LoRA ✔ | Wan 2.2 14B fp8 ✔, Wan Animate ✔ (lent), HunyuanVideo 1.5 ✔ | ✔✔ | ✔✔ |
| 5 | ≥ 24 Go | RTX 3090, 4090, 5090, RX 7900 XTX | Tout ✔✔ | Tout, y compris Wan Animate / remplacement de personnage ✔✔ | ✔✔ | ✔✔ |

Avec **16 Go de RAM système**, les paliers 3-4 en vidéo seront plus lents que la normale (déchargement limité) : voir la section RAM.

### Ordres de grandeur de temps (palier 2-3, NVIDIA)

- Image SDXL 1024² : 5-15 s · Z-Image Turbo : 5-10 s · Flux dev GGUF : 30-90 s
- Face swap FaceFusion : ~1 à 3 × la durée de la vidéo (avec amélioration du visage)
- Vidéo Wan 2.2 5B, 5 s en 720p : 5-15 min · Wan 14B GGUF + lightx2v, 5 s en 480p : 3-10 min
- Clonage de voix Chatterbox : quelques secondes par phrase
- Entraîner un modèle de voix RVC (Applio) : 30-90 min

### Quand la VRAM ne suffit pas, dans l'ordre

1. Version **GGUF** (quantifiée) du modèle — Q8 ≈ qualité d'origine, Q4 = bien plus léger, un peu moins fin
2. Résolution / durée plus faibles, puis **upscale** et **interpolation** d'images (RIFE) après coup
3. Option `--lowvram` de ComfyUI, ou `--reserve-vram 1`
4. **Louer un GPU à l'heure** (RunPod, Vast.ai : quelques dizaines de centimes l'heure) — voir `options-payantes.md`
5. Service en ligne clé en main (Kling, Hailuo…)
