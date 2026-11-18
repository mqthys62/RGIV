#!/usr/bin/env python3
"""Transcription audio/vidéo → texte + sous-titres .srt (faster-whisper).

  bash scripts/lancer/py.sh audio scripts/voix/transcrire.py projet/entrees/videos/extrait.mp4
  → crée extrait.srt et extrait.txt à côté de --sortie (par défaut : projet/sorties/transcriptions/)

Options : --modele large-v3 (meilleur, défaut si GPU) | medium | small (rapide, défaut si CPU)
          --langue fr (défaut) ; --mots pour avoir l'horodatage mot par mot dans un .json
"""
import argparse
import json
import os


def ts(t):
    h, rem = divmod(t, 3600)
    m, s = divmod(rem, 60)
    return f"{int(h):02d}:{int(m):02d}:{int(s):02d},{int((s % 1) * 1000):03d}"


def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("fichier")
    ap.add_argument("--sortie", default="projet/sorties/transcriptions")
    ap.add_argument("--modele")
    ap.add_argument("--langue", default="fr")
    ap.add_argument("--mots", action="store_true")
    a = ap.parse_args()

    from faster_whisper import WhisperModel
    try:
        import torch
        gpu = torch.cuda.is_available() and torch.version.cuda is not None  # ctranslate2 : NVIDIA uniquement
    except Exception:
        gpu = False
    modele = a.modele or ("large-v3" if gpu else "small")
    print(f"Modèle {modele} sur {'GPU' if gpu else 'CPU'}…", flush=True)
    model = WhisperModel(modele, device="cuda" if gpu else "cpu", compute_type="float16" if gpu else "int8")
    segments, info = model.transcribe(a.fichier, language=a.langue, vad_filter=True, word_timestamps=a.mots)

    os.makedirs(a.sortie, exist_ok=True)
    base = os.path.join(a.sortie, os.path.splitext(os.path.basename(a.fichier))[0])
    srt, txt, mots = [], [], []
    for i, s in enumerate(segments, 1):
        print(f"[{ts(s.start)}] {s.text.strip()}", flush=True)
        srt.append(f"{i}\n{ts(s.start)} --> {ts(s.end)}\n{s.text.strip()}\n")
        txt.append(s.text.strip())
        if a.mots and s.words:
            mots += [{"mot": w.word, "debut": w.start, "fin": w.end} for w in s.words]
    open(base + ".srt", "w", encoding="utf-8").write("\n".join(srt))
    open(base + ".txt", "w", encoding="utf-8").write("\n".join(txt) + "\n")
    if a.mots:
        json.dump(mots, open(base + ".json", "w", encoding="utf-8"), ensure_ascii=False, indent=1)
    print(f"→ {base}.srt / .txt")


if __name__ == "__main__":
    main()
