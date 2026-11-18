---
name: idees
description: Brainstorm de montages pour l'anniversaire à partir de ce qu'il raconte sur sa femme (films, séries, blagues, souvenirs), puis plan de production réaliste selon le matériel et le temps restant. Tient à jour projet/idees.md.
---

# Idées de montages + plan de production

## 1. Faire connaissance (léger, une question groupée à la fois)

- Ses films / séries / dessins animés / chanteurs préférés ? Une réplique culte qu'elle répète ?
- Les private jokes du couple, de la famille, du groupe d'amis ?
- Animaux, lieux, voyages marquants, son métier, ses passions ?
- Qui sera à la fête ? (on peut les intégrer aussi, avec leur accord)
- Le format de diffusion : projection sur la télé, vidéo envoyée sur le groupe de la famille, diaporama ?
- Quels fichiers il a : photos nettes de son visage (de face, bien éclairées), vidéos où elle parle, voix de proches…

## 2. Proposer 8-12 idées, classées par difficulté

Pour chaque idée : une phrase drôle qui la décrit + outils + faisable en local sur SA config ? (sinon coût).

Banque d'idées à adapter :
- **Bande-annonce** de son film préféré où elle est l'héroïne (face swap sur 4-6 extraits + voix off « Cette année… » clonée d'une voix de bande-annonce + titre)
- **Faux JT / flash spécial** : « Ce soir, un événement historique : X fête ses Y ans » (fond généré, présentateur = lui ou un proche, voix clonée, bandeau défilant ffmpeg)
- **Messages de stars** : parodie évidente, voix clonée d'une célébrité qu'elle adore qui lui souhaite bon anniversaire (privé, clairement une blague)
- **Le chat / le chien parle** : photo de l'animal animée (LivePortrait ou image→vidéo) + voix rigolote + lip sync
- **Elle à travers les âges / les époques** : portraits générés (années 20, viking, astronaute, reine d'Égypte) + face swap, en diaporama animé
- **Affiches et couvertures** : fausse couverture de magazine, affiche de film, paquet de céréales à son effigie (Qwen-Image pour le texte)
- **Réplique culte détournée** : un extrait de film avec le dialogue remplacé (séparation voix/musique, nouveau texte en voix clonée de l'acteur, lip sync)
- **Chanson perso** : Suno ou ACE-Step avec des paroles sur sa vie, clip avec des photos animées
- **Message du futur** : elle à 80 ans (vieillissement via édition d'image) qui lui parle
- **Photos d'enfance qui prennent vie** : vieilles photos restaurées, colorisées, animées
- **Les proches dans la scène culte** : chaque invité devient un personnage du film préféré du couple

## 3. Plan de production

Avec la date de l'anniversaire, le palier matériel et le budget :
- trie les idées en **sûres** (outils légers, ex : face swap, voix) et **ambitieuses** (vidéo générée lourde) ;
- commence par les sûres pour avoir un résultat garanti, puis les ambitieuses ;
- prévois une marge (rendus ratés, à refaire) et **garde les 2 derniers jours pour le montage final et l'export**.

Écris/maj `projet/idees.md` :

```markdown
## N. Titre de l'idée
- Statut : idée | en cours | fait | abandonné
- Entrées nécessaires : (fichiers à fournir, ✔ quand reçu)
- Outils : …
- Sortie : projet/sorties/…
- Notes : prompts, réglages qui ont marché, problèmes
```

Termine en lui disant précisément **quels fichiers il doit te fournir** pour la première idée et dans quel dossier les mettre.
