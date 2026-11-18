# Fedora : pilotes et pièges connus

## Principe

- Ce qui demande `sudo` : **l'utilisateur le lance lui-même** dans un autre terminal. Tout est regroupé dans `sudo bash scripts/install/00_systeme_fedora.sh` (dépôts RPM Fusion, outils de base, ffmpeg complet, pilote GPU, Kdenlive) et `sudo bash scripts/install/01_swap.sh` (swap).
- Le reste (Python, outils IA, modèles) est en espace utilisateur dans `outils/`, avec `uv` (qui télécharge lui-même la bonne version de Python : pas besoin de toucher au Python de Fedora, souvent trop récent pour les outils IA).
- Fedora change de version tous les 6 mois. Si un nom de paquet a changé, cherche le nouveau (`dnf search …`) et corrige le script.

## NVIDIA

1. Dépôts RPM Fusion free + nonfree, puis `akmod-nvidia` + `xorg-x11-drv-nvidia-cuda` (fournit `nvidia-smi`).
2. **Attendre que le module soit compilé** (`modinfo -F version nvidia` doit répondre, 3 à 10 min) **avant** de redémarrer.
3. **Secure Boot activé** (c'est son cas) : le module doit être signé. Le script crée la clé (`kmodgenca`) et l'importe (`mokutil --import`, demande de choisir un mot de passe). **Au redémarrage**, écran bleu « Perform MOK management » → *Enroll MOK* → *Continue* → *Yes* → mot de passe → *Reboot*. S'il rate l'écran, relancer le script et redémarrer. Alternative : désactiver Secure Boot dans le BIOS (déconseillé si dual boot Windows avec BitLocker).
4. Vérifier : `nvidia-smi`. Si « NVIDIA-SMI has failed » : `mokutil --list-enrolled | grep -i akmods` (clé enrôlée ?), `lsmod | grep nvidia`, `journalctl -b | grep -i nvidia`, `sudo akmods --force --rebuild`.
5. **Pas besoin d'installer le CUDA Toolkit** : PyTorch embarque son CUDA. Pour onnxruntime (FaceFusion) et ctranslate2 (Whisper), les bibliothèques CUDA/cuDNN sont installées en paquets pip dans chaque venv et `scripts/lancer/env.sh` les rend visibles (`LD_LIBRARY_PATH`).
6. Après une **mise à jour du noyau**, akmods recompile tout seul au démarrage suivant (premier démarrage un peu plus long). Si le GPU disparaît après une mise à jour : `sudo akmods --force` puis redémarrage.
7. Index PyTorch : `cu128` par défaut (RTX 20xx à 50xx). Pour une GTX 10xx (Pascal) ou plus ancienne, les builds récents ne la supportent plus : prendre `cu126` (`TORCH_INDEX=https://download.pytorch.org/whl/cu126`). Vérifier sur pytorch.org/get-started/locally.
8. Wayland + NVIDIA fonctionne bien avec les pilotes récents ; en cas de souci d'affichage, choisir « GNOME sur Xorg » à l'écran de connexion (si encore proposé).

## AMD (ROCm)

1. Le pilote graphique `amdgpu` est déjà dans le noyau : rien à installer pour l'affichage.
2. Pour le calcul : PyTorch ROCm embarque son runtime. Le script installe juste `rocminfo` / `rocm-smi` (diagnostic) et ajoute l'utilisateur aux groupes `render` et `video` (**se déconnecter / reconnecter** ensuite).
3. Cartes grand public pas officiellement supportées : forcer la version GFX dans `etat/profil.env.local` (relu par les lanceurs) :
   - RX 6000 (RDNA2, gfx103x) : `HSA_OVERRIDE_GFX_VERSION=10.3.0`
   - RX 7000 (RDNA3, gfx110x) : `HSA_OVERRIDE_GFX_VERSION=11.0.0` (inutile pour 7900 XTX/XT, gfx1100)
   - RX 9000 (RDNA4, gfx120x) : supporté nativement par ROCm récent (≥ 6.4) ; prendre l'index PyTorch ROCm le plus récent.
   `rocminfo | grep gfx` donne la valeur réelle.
4. Vérifier : `bash scripts/lancer/py.sh ComfyUI -c "import torch; print(torch.cuda.is_available(), torch.cuda.get_device_name(0))"` (oui, l'API s'appelle `cuda` même sous AMD).
5. FaceFusion : fournisseur `rocm` (ou `migraphx` selon la version). Si ça coince, le mode CPU reste possible.
6. faster-whisper (ctranslate2) n'a pas de support ROCm : il tourne sur CPU (`small`/`medium` restent rapides sur un 5800X).

## ffmpeg

Fedora installe par défaut `ffmpeg-free`, sans encodeur H.264/H.265. Le script le remplace par le ffmpeg complet de RPM Fusion (`dnf swap ffmpeg-free ffmpeg --allowerasing`). Vérifier : `ffmpeg -encoders | grep -E 'libx264|nvenc'`.

## Divers

- **SELinux** est actif sur Fedora : en cas de « Permission denied » inexplicable sur un fichier, regarder `sudo ausearch -m avc -ts recent`. Très rare pour ce projet (tout est dans le dossier perso).
- **Disque** : Fedora utilise btrfs par défaut. Les modèles sont gros : vérifier `df -h ~`.
- Pour surveiller le GPU en direct : `nvtop` (NVIDIA et AMD).
- Ouvrir un fichier/dossier depuis le terminal : `xdg-open projet/sorties/`.
