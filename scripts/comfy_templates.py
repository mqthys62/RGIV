#!/usr/bin/env python3
"""Explore les templates officiels de ComfyUI (installés avec lui) et télécharge les modèles qu'ils demandent.

Chaque template officiel indique les fichiers de modèles nécessaires (nom, URL, dossier). C'est la façon
la plus fiable d'obtenir des modèles compatibles, sans deviner les noms de fichiers.

  python3 scripts/comfy_templates.py list                 # tous les templates
  python3 scripts/comfy_templates.py list wan             # filtrer (wan, flux, qwen, ltx, hunyuan, sdxl…)
  python3 scripts/comfy_templates.py models video_wan2_2_5B_ti2v      # modèles requis + taille + déjà présents ?
  python3 scripts/comfy_templates.py download video_wan2_2_5B_ti2v    # télécharger ce qui manque (reprise possible)
  python3 scripts/comfy_templates.py path video_wan2_2_5B_ti2v        # chemin du JSON (pour l'ouvrir dans l'UI)

Rappel : un template est au format « interface ». Pour l'exécuter via scripts/comfy_run.py, l'ouvrir dans
ComfyUI (Workflow → Browse Templates), le tester, puis Workflow → Export (API) vers workflows/.
"""
import glob
import json
import os
import sys
import urllib.error
import urllib.request

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
COMFY = os.path.join(ROOT, "outils", "ComfyUI")


def template_files():
    pats = [os.path.join(COMFY, ".venv", "lib", "python3*", "site-packages", "comfyui_workflow_templates*", "**", "*.json")]
    files = {}
    for p in pats:
        for f in glob.glob(p, recursive=True):
            base = os.path.basename(f)[:-5]
            if base in ("index", "index.schema") or base.startswith("index"):
                continue
            files.setdefault(base, f)
    return files


def find_models(obj, acc):
    if isinstance(obj, dict):
        if {"name", "url", "directory"} <= obj.keys() and str(obj["url"]).startswith("http"):
            acc[(obj["directory"], obj["name"])] = obj["url"]
        for v in obj.values():
            find_models(v, acc)
    elif isinstance(obj, list):
        for v in obj:
            find_models(v, acc)
    return acc


def remote_size(url):
    try:
        req = urllib.request.Request(url, method="HEAD")
        with urllib.request.urlopen(req, timeout=20) as r:
            return int(r.headers.get("Content-Length") or r.headers.get("X-Linked-Size") or 0)
    except Exception:
        return 0


def human(n):
    return f"{n / 1e9:.1f} Go" if n else "?"


def get_template(name):
    files = template_files()
    if not files:
        sys.exit("Aucun template trouvé : ComfyUI est-il installé ? (bash scripts/install/comfyui.sh)")
    if name not in files:
        close = [k for k in files if name.lower() in k.lower()]
        sys.exit(f"Template « {name} » introuvable." + (f" Proches : {', '.join(close[:15])}" if close else ""))
    with open(files[name]) as f:
        return files[name], json.load(f)


def download(url, dest):
    os.makedirs(os.path.dirname(dest), exist_ok=True)
    part = dest + ".part"
    have = os.path.getsize(part) if os.path.exists(part) else 0
    headers = {"Range": f"bytes={have}-"} if have else {}
    tok = os.environ.get("HF_TOKEN")
    if tok and "huggingface.co" in url:
        headers["Authorization"] = f"Bearer {tok}"
    req = urllib.request.Request(url, headers=headers)
    with urllib.request.urlopen(req, timeout=60) as r:
        total = int(r.headers.get("Content-Length", 0)) + have
        mode = "ab" if have and r.status == 206 else "wb"
        done = have if mode == "ab" else 0
        with open(part, mode) as f:
            last = 0
            while True:
                chunk = r.read(8 << 20)
                if not chunk:
                    break
                f.write(chunk)
                done += len(chunk)
                if done - last > 500e6:
                    last = done
                    print(f"    {human(done)} / {human(total)}", flush=True)
    os.replace(part, dest)


def main():
    if len(sys.argv) < 2 or sys.argv[1] not in ("list", "models", "download", "path"):
        sys.exit(__doc__)
    cmd = sys.argv[1]
    arg = sys.argv[2] if len(sys.argv) > 2 else ""
    if cmd == "list":
        if not template_files():
            sys.exit("Aucun template trouvé : ComfyUI est-il installé ? (bash scripts/install/comfyui.sh)")
        for k in sorted(template_files()):
            if arg.lower() in k.lower():
                print(k)
        return
    if not arg:
        sys.exit("Précise le nom du template (voir : list)")
    path, data = get_template(arg)
    if cmd == "path":
        print(path)
        return
    models = find_models(data, {})
    if not models:
        print("Ce template ne déclare aucun modèle (il en a peut-être besoin quand même : regarder les nœuds de chargement).")
        return
    total = 0
    todo = []
    for (d, n), url in sorted(models.items()):
        dest = os.path.join(COMFY, "models", d, n)
        present = os.path.exists(dest)
        size = 0 if present else remote_size(url)
        total += size
        print(f"{'✔' if present else '·'} {d}/{n}  {'(présent)' if present else human(size)}\n    {url}")
        if not present:
            todo.append((url, dest))
    print(f"\nÀ télécharger : {len(todo)} fichier(s), ~{human(total)}")
    if cmd == "download":
        for url, dest in todo:
            print(f"↓ {os.path.relpath(dest, ROOT)}", flush=True)
            try:
                download(url, dest)
            except urllib.error.HTTPError as e:
                if e.code in (401, 403):
                    print("  ✖ Accès refusé : modèle « gated » sur Hugging Face. Accepter la licence sur la page du modèle,"
                          " créer un token (huggingface.co/settings/tokens) et relancer avec HF_TOKEN=… ")
                else:
                    print(f"  ✖ Erreur HTTP {e.code}")
        print("Terminé.")


if __name__ == "__main__":
    main()
