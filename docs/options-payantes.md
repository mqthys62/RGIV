# Options payantes (ou gratuites en ligne) quand le PC ne suit pas

> **Les prix ci-dessous sont des ordres de grandeur (fin 2025 – 2026). Vérifie toujours par une recherche web avant de les annoncer**, les offres changent tous les mois. Présente-les toujours comme un choix : « gratuit en local mais 2 h de calcul », ou « 3 € et 10 minutes ».

## Règle de confidentialité

Envoyer des photos/voix de proches à un service en ligne, c'est les confier à un tiers. Préférer : le local d'abord, sinon un **GPU loué** (on y installe nos propres outils, on efface après), sinon un service connu (Kling, ElevenLabs, Suno…). **Jamais** les sites obscurs de « face swap gratuit ».

## 1. Louer une carte graphique à l'heure — le meilleur rapport qualité/prix

On loue un PC distant avec une grosse carte (RTX 4090, 5090, A100…), on y fait tourner **le même ComfyUI / FaceFusion** que chez soi, puis on récupère les fichiers.

| Service | Prix indicatif | Remarque |
|---|---|---|
| **RunPod** | RTX 4090 ~0,35-0,70 $/h, 5090 un peu plus | Modèles (« templates ») ComfyUI prêts à l'emploi, simple. Recharge minimum ~10 $ |
| **Vast.ai** | RTX 3090 ~0,15-0,30 $/h, 4090 ~0,30-0,50 $/h | Moins cher, un peu moins simple |

**10 € ≈ 15 à 30 heures de RTX 4090.** C'est largement de quoi faire tous les plans vidéo lourds (Wan 14B, Wan Animate, entraînement de LoRA) en une ou deux soirées. Penser à **arrêter le pod** après usage (le stockage continue à coûter quelques centimes/jour).

Tu peux le guider pas à pas : création du compte, choix du template ComfyUI, envoi des fichiers (interface web du pod ou `scp`/`rsync`), lancement des workflows avec `scripts/comfy_run.py --server <url du pod>`.

## 2. Services vidéo en ligne (clé en main)

| Service | Offre | Points forts |
|---|---|---|
| **Kling AI** | Crédits gratuits quotidiens ; abonnement dès ~7-10 $/mois | Image→vidéo excellente, gestes réalistes, effets marrants |
| **Hailuo (MiniMax)** | Crédits gratuits ; abonnement ~10 $/mois | Très bon image→vidéo |
| **Google Veo** (via Gemini / Flow) | Inclus dans certains abonnements Google AI | Vidéo avec son et dialogues |
| **Runway** | ~12-15 $/mois | Outils d'édition (remplacement de personnage, restyle) |
| **fal.ai / Replicate** | Paiement à l'usage, sans abonnement : de quelques centimes (image) à ~0,5-2 $ (clip vidéo de 5 s) | Accès aux mêmes modèles open source (Wan, Flux, Kling…) via une API : Claude peut les piloter avec une clé |

## 3. Voix

| Service | Offre | Remarque |
|---|---|---|
| **ElevenLabs** | Gratuit limité (sans clonage) ; **Starter ~5-6 $/mois avec clonage instantané** | Le meilleur clonage en français, très simple. 1 mois suffit |
| **Suno** | **Gratuit : ~10 chansons/jour** (usage non commercial = parfait ici) ; Pro ~10 $/mois | Chanson d'anniversaire perso avec paroles en français, en 30 s |
| **Udio** | Similaire à Suno | — |

## 4. Matériel

| Achat | Prix | Gain |
|---|---|---|
| Activer DOCP dans le BIOS | 0 € | +50 % de bande passante RAM |
| +16 Go de RAM DDR4 (32 Go au total) | à vérifier (la DDR4 a beaucoup augmenté en 2025-2026) | Vidéo locale beaucoup plus confortable |
| Changer de carte graphique | des centaines d'€ | Hors sujet pour un anniversaire : la location à l'heure est bien plus rentable |

## Comment présenter le choix (exemple)

> « Pour le plan où ta femme remplace l'actrice dans Titanic, ta carte de 8 Go ne suffit pas pour Wan Animate. Trois options :
> 1. **Gratuit** : on fait un face swap avec FaceFusion (son visage sur l'actrice, le corps reste celui de l'actrice). Rendu bluffant pour le visage, 20 min de calcul.
> 2. **~2-3 €** : on loue une RTX 4090 sur RunPod pendant 2-3 h et on fait le vrai remplacement complet.
> 3. **Kling** avec les crédits gratuits : on anime une photo d'elle dans une scène façon Titanic (pas l'extrait original). »
