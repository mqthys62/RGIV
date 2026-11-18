#!/usr/bin/env python3
"""Exécute un workflow ComfyUI (format API) et récupère les résultats. Bibliothèque standard uniquement.

ComfyUI doit tourner (bash scripts/lancer/comfyui.sh).

Exemples :
  python3 scripts/comfy_run.py workflows/txt2img_checkpoint.json \\
      --set 6.text="une femme astronaute sur la lune, photo réaliste" --set 3.seed=42 \\
      --out projet/sorties/2026-12-01_astronaute

  # @chemin = le fichier est d'abord envoyé à ComfyUI, puis son nom est injecté
  python3 scripts/comfy_run.py workflows/mon_i2v.json --set 52.image=@projet/entrees/photos/julie.jpg

  python3 scripts/comfy_run.py --list-nodes workflows/mon_i2v.json   # voir les nœuds et leurs entrées

Obtenir un workflow au format API : dans ComfyUI, ouvrir le workflow, puis menu Workflow → Export (API).
"""
import argparse
import json
import mimetypes
import os
import sys
import time
import urllib.error
import urllib.parse
import urllib.request
import uuid


def http(server, path, data=None, headers=None, timeout=60):
    req = urllib.request.Request(server + path, data=data, headers=headers or {})
    with urllib.request.urlopen(req, timeout=timeout) as r:
        return r.read()


def upload(server, path):
    boundary = uuid.uuid4().hex
    name = os.path.basename(path)
    ctype = mimetypes.guess_type(name)[0] or "application/octet-stream"
    with open(path, "rb") as f:
        content = f.read()
    body = (
        f"--{boundary}\r\nContent-Disposition: form-data; name=\"image\"; filename=\"{name}\"\r\n"
        f"Content-Type: {ctype}\r\n\r\n"
    ).encode() + content + (
        f"\r\n--{boundary}\r\nContent-Disposition: form-data; name=\"overwrite\"\r\n\r\ntrue"
        f"\r\n--{boundary}--\r\n"
    ).encode()
    res = json.loads(http(server, "/upload/image", body, {"Content-Type": f"multipart/form-data; boundary={boundary}"}, 600))
    return (res.get("subfolder", "") + "/" if res.get("subfolder") else "") + res["name"]


def parse_value(raw, server):
    if raw.startswith("@"):
        return upload(server, raw[1:])
    try:
        return json.loads(raw)
    except json.JSONDecodeError:
        return raw


def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("workflow", help="fichier JSON au format API")
    ap.add_argument("--set", action="append", default=[], metavar="NODE.INPUT=VALEUR",
                    help="modifier une entrée (VALEUR en JSON si possible, sinon texte ; @fichier = upload)")
    ap.add_argument("--server", default=os.environ.get("COMFY_URL", "http://127.0.0.1:8188"))
    ap.add_argument("--out", help="dossier où copier les résultats (sinon : ils restent dans projet/sorties/comfyui)")
    ap.add_argument("--timeout", type=int, default=7200, help="secondes max d'attente (défaut 2 h)")
    ap.add_argument("--list-nodes", action="store_true", help="afficher les nœuds du workflow et quitter")
    a = ap.parse_args()

    with open(a.workflow) as f:
        wf = json.load(f)
    if "nodes" in wf and "links" in wf:
        sys.exit("Ce fichier est au format « interface », pas « API ». Dans ComfyUI : Workflow → Export (API).")

    if a.list_nodes:
        for nid, node in wf.items():
            title = node.get("_meta", {}).get("title", "")
            simples = {k: v for k, v in node.get("inputs", {}).items() if not isinstance(v, list)}
            print(f"[{nid}] {node.get('class_type')} {('« ' + title + ' »') if title else ''}")
            for k, v in simples.items():
                print(f"      {k} = {json.dumps(v, ensure_ascii=False)[:100]}")
        return

    try:
        http(a.server, "/system_stats", timeout=5)
    except Exception:
        sys.exit(f"ComfyUI ne répond pas sur {a.server}. Lance-le : bash scripts/lancer/comfyui.sh")

    for s in a.set:
        key, _, raw = s.partition("=")
        nid, _, inp = key.partition(".")
        if nid not in wf:
            sys.exit(f"Nœud {nid} absent du workflow (utilise --list-nodes)")
        wf[nid].setdefault("inputs", {})[inp] = parse_value(raw, a.server)

    client_id = uuid.uuid4().hex
    try:
        res = json.loads(http(a.server, "/prompt", json.dumps({"prompt": wf, "client_id": client_id}).encode(),
                              {"Content-Type": "application/json"}))
    except urllib.error.HTTPError as e:
        sys.exit("Workflow refusé par ComfyUI :\n" + e.read().decode(errors="replace")[:4000])
    pid = res["prompt_id"]
    print(f"Envoyé (prompt_id={pid}), en cours…", flush=True)

    t0 = time.time()
    hist = None
    while time.time() - t0 < a.timeout:
        time.sleep(3)
        h = json.loads(http(a.server, f"/history/{pid}"))
        if pid in h:
            hist = h[pid]
            break
        el = int(time.time() - t0)
        if el % 30 < 3:
            print(f"  … {el // 60} min {el % 60:02d} s", flush=True)
    if hist is None:
        sys.exit("Délai dépassé (le travail continue peut-être dans ComfyUI).")

    status = hist.get("status", {})
    if status.get("status_str") == "error":
        msgs = [m for m in status.get("messages", []) if m[0] == "execution_error"]
        sys.exit("Erreur d'exécution :\n" + json.dumps(msgs, indent=1, ensure_ascii=False)[:4000])

    saved = []
    if a.out:
        os.makedirs(a.out, exist_ok=True)
    for node_out in hist.get("outputs", {}).values():
        for items in node_out.values():
            if not isinstance(items, list):
                continue
            for it in items:
                if not (isinstance(it, dict) and "filename" in it) or it.get("type") == "temp":
                    continue
                if a.out:
                    q = urllib.parse.urlencode({"filename": it["filename"], "subfolder": it.get("subfolder", ""),
                                                "type": it.get("type", "output")})
                    dest = os.path.join(a.out, it["filename"])
                    with open(dest, "wb") as f:
                        f.write(http(a.server, f"/view?{q}", timeout=600))
                    saved.append(dest)
                else:
                    saved.append(os.path.join("projet/sorties/comfyui", it.get("subfolder", ""), it["filename"]))
    print(f"Terminé en {int(time.time() - t0)} s.")
    for p in saved:
        print("→", p)


if __name__ == "__main__":
    main()
