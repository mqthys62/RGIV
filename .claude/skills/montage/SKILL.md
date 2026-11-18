---
name: montage
description: Découper, assembler, remplacer ou mixer l'audio, ajouter titres et sous-titres, faire un diaporama animé, et exporter pour la télé ou le téléphone, avec ffmpeg (et Kdenlive pour les retouches à la souris).
---

# Montage avec ffmpeg

Toujours : travailler sur des copies dans `projet/sorties/<date>_<nom>/`, vérifier avec `ffprobe` (durées, résolution, fps, présence d'audio) avant d'assembler, et regarder quelques images du résultat. Sortie finale en H.264 + AAC, `yuv420p`, `+faststart` = lisible partout (télé, téléphone, WhatsApp).

Si NVENC est dispo (`ffmpeg -encoders | grep nvenc`), `-c:v h264_nvenc -cq 21` est bien plus rapide que `libx264 -crf 18`.

## Recettes

**Découper un extrait** (précis à l'image, ré-encode) :
```bash
ffmpeg -ss 00:12:03.5 -to 00:12:15 -i film.mkv -c:v libx264 -crf 18 -preset fast -c:a aac -b:a 192k extrait.mp4
```

**Mettre plusieurs clips au même format** (indispensable avant de concaténer) :
```bash
ffmpeg -i clip.mp4 -vf "scale=1920:1080:force_original_aspect_ratio=decrease,pad=1920:1080:(ow-iw)/2:(oh-ih)/2,fps=25,format=yuv420p" \
  -c:v libx264 -crf 18 -c:a aac -ar 48000 -ac 2 clip_norm.mp4
```
(clip sans audio : ajouter `-f lavfi -i anullsrc=r=48000:cl=stereo -shortest` pour une piste muette, sinon la concaténation échoue.)

**Concaténer** (clips déjà normalisés) :
```bash
printf "file '%s'\n" clip1_norm.mp4 clip2_norm.mp4 clip3_norm.mp4 > liste.txt
ffmpeg -f concat -safe 0 -i liste.txt -c copy final.mp4
```

**Fondu entre deux clips** :
```bash
ffmpeg -i a.mp4 -i b.mp4 -filter_complex \
 "[0:v][1:v]xfade=transition=fade:duration=1:offset=<durée_a - 1>[v];[0:a][1:a]acrossfade=d=1[a]" \
 -map "[v]" -map "[a]" -c:v libx264 -crf 18 -c:a aac ab.mp4
```

**Remplacer l'audio** / **mixer un nouveau dialogue sur la musique d'origine** :
```bash
ffmpeg -i video.mp4 -i nouvel_audio.wav -map 0:v -map 1:a -c:v copy -c:a aac -shortest out.mp4
ffmpeg -i video.mp4 -i instrumental.wav -i dialogue.wav -filter_complex \
 "[2:a]adelay=1500|1500,volume=1.2[d];[1:a][d]amix=inputs=2:duration=first:normalize=0[a]" \
 -map 0:v -map "[a]" -c:v copy -c:a aac out.mp4
```
(`adelay` en millisecondes = moment où commence la réplique.)

**Musique de fond qui baisse quand on parle** (ducking) :
```bash
ffmpeg -i voix.wav -i musique.mp3 -filter_complex \
 "[1:a]volume=0.6[m];[m][0:a]sidechaincompress=threshold=0.05:ratio=8:attack=20:release=400[md];[md][0:a]amix=inputs=2:normalize=0[a]" \
 -map "[a]" mix.wav
```

**Incruster des sous-titres** (.srt), style lisible :
```bash
ffmpeg -i in.mp4 -vf "subtitles=sous_titres.srt:force_style='FontName=DejaVu Sans,FontSize=24,Outline=2,MarginV=40'" -c:a copy out.mp4
```

**Titre / texte à l'écran** (ex : carton façon bande-annonce) :
```bash
ffmpeg -i in.mp4 -vf "drawtext=text='CET HIVER...':fontfile=/usr/share/fonts/dejavu-sans-fonts/DejaVuSans-Bold.ttf:fontsize=72:fontcolor=white:x=(w-tw)/2:y=(h-th)/2:enable='between(t,0,3)':alpha='if(lt(t,0.5),t/0.5,if(gt(t,2.5),(3-t)/0.5,1))'" -c:a copy out.mp4
```
(trouver les polices : `fc-list | grep -i bold`.) Carton noir seul : `ffmpeg -f lavfi -i color=black:s=1920x1080:d=3:r=25 -vf drawtext=… carton.mp4`.

**Diaporama animé façon Ken Burns** (une photo → 5 s de zoom lent) :
```bash
ffmpeg -loop 1 -i photo.jpg -vf "scale=3840:-2,zoompan=z='min(zoom+0.0008,1.2)':x='iw/2-(iw/zoom/2)':y='ih/2-(ih/zoom/2)':d=125:s=1920x1080:fps=25,format=yuv420p" -t 5 -c:v libx264 -crf 18 photo.mp4
```

**Ralenti / accéléré** : `-vf "setpts=2.0*PTS" -af "atempo=0.5"` (ralenti ×2).

**Export final pour la télé / clé USB** :
```bash
ffmpeg -i final.mp4 -c:v libx264 -crf 18 -preset slow -pix_fmt yuv420p -c:a aac -b:a 192k -movflags +faststart ANNIV_final.mp4
```
**Version légère pour WhatsApp** : `-vf scale=-2:720 -crf 26`.

## Kdenlive (pour lui)

Pour les retouches à la souris (calage précis, transitions, titres), il peut ouvrir Kdenlive (menu des applications) et glisser les fichiers de `projet/sorties/`. Explique-lui les bases si besoin : importer → glisser dans la timeline → couper avec `Maj+R` → exporter avec le bouton « Rendu » (profil MP4 H.264).

## Le jour J

Prévoir : un fichier final unique (ou un par séquence), testé **sur l'appareil de diffusion** (télé, vidéoprojecteur) la veille, une copie sur clé USB, et une copie sur le téléphone.
