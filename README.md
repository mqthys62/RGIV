# 🎂 Studio anniversaire surprise

Un kit prêt à l'emploi pour créer en local, sur ton PC Fedora, des montages marrants pour l'anniversaire de ta femme : images, vidéos, visages incrustés dans des extraits de films, voix clonées, chansons…

**Tu n'as rien à lire ni à configurer : c'est Claude qui s'occupe de tout.** Il analyse ton PC, t'explique ce qui est possible, installe les outils et fait les montages avec toi.

## Installation (une seule fois, ~5 minutes)

Ouvre un **Terminal** (touche Super/Windows → tape « Terminal ») et copie ces commandes une par une :

**1. Installer Claude Code**
```bash
curl -fsSL https://claude.ai/install.sh | bash
```
Ferme et rouvre le terminal ensuite. (Il faut un abonnement Claude Pro ou Max, ou un compte API : à la première ouverture, Claude te demandera de te connecter dans le navigateur.)

**2. Récupérer ce dossier**
```bash
git clone https://github.com/mqthys62/RGIV.git ~/anniversaire
```

**3. Lancer Claude dedans**
```bash
cd ~/anniversaire
claude
```

**4. Dis-lui juste « salut »** 👋. Au premier lancement il fait le diagnostic de ton PC et te propose un plan.

## Ensuite, à chaque fois

```bash
cd ~/anniversaire && claude
```
Il se souvient de où vous en êtes (dans le dossier `etat/`).

## Où mettre tes fichiers

| Quoi | Où |
|---|---|
| Photos (visages bien nets, de face) | `projet/entrees/photos/` |
| Extraits de films / vidéos | `projet/entrees/videos/` |
| Enregistrements de voix | `projet/entrees/voix/` |
| Musiques | `projet/entrees/musique/` |
| **Tous les résultats** | `projet/sorties/` |

Ou dis simplement à Claude « j'ai mis les photos dans Téléchargements », il les rangera.

## Commandes rapides (à taper dans Claude)

| Commande | Ça fait quoi |
|---|---|
| `/demarrage` | Diagnostic du PC + plan (refaire si tu changes de matériel) |
| `/idees` | Trouver des idées de montages et planifier |
| `/faceswap` | Mettre un visage dans une photo ou un extrait de film |
| `/image` | Générer des images |
| `/video` | Générer / animer des vidéos |
| `/voix` | Cloner une voix, faux audios, chanson |
| `/montage` | Assembler, sous-titrer, exporter |
| `/installer` | Installer ou réparer un outil |

Tu peux aussi juste parler normalement : « je veux que ma femme soit Rose dans Titanic ».

## Bon à savoir

- Parfois Claude te demandera de lancer une commande avec `sudo` **dans un autre terminal** (il ne peut pas taper ton mot de passe). C'est normal : il t'explique à chaque fois ce que ça fait.
- Les outils et modèles prennent de la place : compte **50 à 200 Go** selon ce que tu fais.
- Tes photos, vidéos et résultats **ne sont jamais envoyés sur GitHub** (ils sont exclus du dépôt).
- C'est une surprise : si ta femme utilise aussi ce PC, range bien tes affaires 😉
