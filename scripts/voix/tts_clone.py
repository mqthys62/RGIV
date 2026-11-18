#!/usr/bin/env python3
"""Texte → voix clonée, avec Chatterbox multilingue (français OK).

  bash scripts/lancer/py.sh chatterbox scripts/voix/tts_clone.py \\
      --ref projet/entrees/voix/tonton_propre.wav \\
      --texte "Joyeux anniversaire ma chérie, c'est moi, ton tonton préféré !" \\
      --sortie projet/sorties/2026-12-01_message-tonton/message.wav

  --texte-fichier script.txt   pour un long texte (découpé automatiquement en phrases)

Conseils pour la référence (--ref) : 10 à 30 s de voix SEULE (pas de musique ni d'autres voix),
un seul locuteur, ton naturel. Isoler la voix d'un extrait : scripts/voix/separer.sh.
Réglages : --exageration (0.25 calme … 0.5 normal … 0.9 très expressif), --cfg (0.3 plus lent/posé, 0.5 normal).
"""
import argparse
import os
import re
import sys


def decouper(texte, maxlen=250):
    phrases = re.split(r"(?<=[.!?…])\s+", texte.strip())
    morceaux, cur = [], ""
    for p in phrases:
        if len(cur) + len(p) + 1 <= maxlen:
            cur = (cur + " " + p).strip()
        else:
            if cur:
                morceaux.append(cur)
            while len(p) > maxlen:  # phrase très longue : couper aux virgules
                cut = p.rfind(",", 0, maxlen)
                cut = cut if cut > 50 else maxlen
                morceaux.append(p[: cut + 1].strip())
                p = p[cut + 1:].strip()
            cur = p
    if cur:
        morceaux.append(cur)
    return morceaux


def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--ref", required=True, help="enregistrement de la voix à imiter (wav/mp3)")
    g = ap.add_mutually_exclusive_group(required=True)
    g.add_argument("--texte")
    g.add_argument("--texte-fichier")
    ap.add_argument("--sortie", required=True)
    ap.add_argument("--langue", default="fr")
    ap.add_argument("--exageration", type=float, default=0.5)
    ap.add_argument("--cfg", type=float, default=0.5)
    ap.add_argument("--temperature", type=float, default=0.8)
    ap.add_argument("--seed", type=int, default=0, help="0 = aléatoire ; fixer pour reproduire un résultat")
    ap.add_argument("--pause", type=float, default=0.25, help="silence entre phrases (s)")
    a = ap.parse_args()

    import torch
    import torchaudio as ta
    from chatterbox.mtl_tts import ChatterboxMultilingualTTS

    texte = a.texte if a.texte else open(a.texte_fichier, encoding="utf-8").read()
    if not os.path.exists(a.ref):
        sys.exit(f"Référence introuvable : {a.ref}")
    if a.seed:
        torch.manual_seed(a.seed)

    device = "cuda" if torch.cuda.is_available() else "cpu"
    print(f"Chargement du modèle sur {device}…", flush=True)
    model = ChatterboxMultilingualTTS.from_pretrained(device=device)

    morceaux = decouper(texte)
    silence = torch.zeros(1, int(model.sr * a.pause))
    sons = []
    for i, m in enumerate(morceaux, 1):
        print(f"[{i}/{len(morceaux)}] {m}", flush=True)
        wav = model.generate(m, language_id=a.langue, audio_prompt_path=a.ref,
                             exaggeration=a.exageration, cfg_weight=a.cfg, temperature=a.temperature)
        sons += [wav.cpu(), silence]
    out = torch.cat(sons[:-1], dim=1)
    os.makedirs(os.path.dirname(os.path.abspath(a.sortie)), exist_ok=True)
    ta.save(a.sortie, out, model.sr)
    print(f"→ {a.sortie} ({out.shape[1] / model.sr:.1f} s)")


if __name__ == "__main__":
    main()
