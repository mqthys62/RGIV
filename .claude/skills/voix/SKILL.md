---
name: voix
description: Cloner une voix et faire de faux audios (faire dire un texte à quelqu'un), convertir sa voix en celle d'un autre (RVC/Applio), isoler une voix ou la musique d'un extrait, transcrire et sous-titrer, chanson d'anniversaire.
---

# Voix et audio

Outils : `outils/chatterbox` (texte→voix clonée), `outils/audio` (séparation + transcription), `outils/applio` (voix→voix). Install : `/installer`.

## 1. Préparer une voix de référence propre (indispensable)

1. Récupérer un enregistrement où la personne parle seule : vocal WhatsApp, vidéo de famille, extrait de film/interview.
2. Si c'est une vidéo ou qu'il y a de la musique/du bruit : `bash scripts/voix/separer.sh <fichier>` → garder le fichier `(Vocals)`.
3. Repérer 10-30 s de parole claire et continue (transcrire aide à trouver le bon passage : `bash scripts/lancer/py.sh audio scripts/voix/transcrire.py <fichier>`).
4. Couper et normaliser :
   ```bash
   ffmpeg -ss 00:00:12 -t 20 -i voix_Vocals.wav -ac 1 -ar 24000 -af "loudnorm" projet/entrees/voix/<prenom>_ref.wav
   ```
   (on écrit dans `entrees/voix` un fichier **nouveau**, l'original n'est pas touché.)

## 2. Faire dire un texte (Chatterbox multilingue)

```bash
bash scripts/lancer/py.sh chatterbox scripts/voix/tts_clone.py \
  --ref projet/entrees/voix/<prenom>_ref.wav \
  --texte "Joyeux anniversaire ! Ici ton grand-père depuis la station spatiale internationale." \
  --sortie projet/sorties/<date>_<nom>/message.wav
```
- Écris le texte **comme on parle** (ponctuation = rythme, « euh », points de suspension pour les pauses).
- Ton : `--exageration 0.3` posé, `0.5` normal, `0.7-0.9` surjoué (parfait pour l'humour) ; baisser `--cfg` à 0.3 si ça parle trop vite.
- Génère 2-3 versions (`--seed` différents), il choisit à l'oreille : donne-lui `xdg-open <fichier>`.
- Si la ressemblance est mauvaise : changer d'extrait de référence (c'est la cause n°1), ou essayer XTTS-v2 (`coqui-tts`) / F5-TTS dans un nouveau venv, ou ElevenLabs (~5 €/mois, le meilleur en français).

## 3. Convertir SA voix en celle de quelqu'un (Applio / RVC) — le plus naturel

Il enregistre lui-même la réplique en imitant le ton (micro du PC ou téléphone), et Applio la transforme en la voix cible. Garde toutes les intonations, rires, chuchotements.
1. Entraîner un modèle : 5-15 min de voix propre de la cible (plusieurs extraits concaténés après séparation), onglet *Train* d'Applio (`cd outils/applio && bash run-applio.sh` → http://127.0.0.1:6969), 200-400 epochs, 30-90 min de GPU.
2. Ou télécharger un modèle RVC existant (voix de personnages/célébrités, sites communautaires) pour une parodie.
3. Onglet *Inference* : son enregistrement → voix cible. Ajuster le *pitch* (+12/-12 pour homme↔femme).
Alternative sans entraînement : Seed-VC (zero-shot).

## 4. Remplacer le dialogue d'un extrait de film

1. `bash scripts/voix/separer.sh extrait.mp4` → voix d'origine + musique/bruitages (Instrumental).
2. Transcrire la voix d'origine pour connaître le timing.
3. Créer le nouveau dialogue (section 2 ou 3) avec la voix de l'acteur, de lui, ou d'un proche, de durée proche.
4. Remixer sur l'instrumental et remettre sur la vidéo (`/montage`), éventuellement lip sync (`/faceswap`).

## 5. Sous-titres

`transcrire.py` produit un `.srt` → le corriger si besoin → incruster (`/montage`). Pour un faux dialogue, écris directement le `.srt`.

## 6. Chanson d'anniversaire

- **Suno** (gratuit ~10 chansons/jour, usage privé) : écris avec lui des paroles en français sur sa vie (refrain avec son prénom, couplets sur leurs souvenirs/private jokes), choisis le style (« variété française années 80 », « rap old school », « comédie musicale Disney »). C'est la voie la plus simple et la meilleure qualité.
- En local : ACE-Step (nœuds ComfyUI ou dépôt dédié, 8 Go+ de VRAM).
- Bonus : remplacer la voix du chanteur par une voix clonée avec Applio.
