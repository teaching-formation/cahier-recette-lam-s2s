#!/usr/bin/env python3
"""
Génère evaluate.html — interface web d'évaluation.
Compatible GitHub Pages : URLs absolues raw, import JSON, auto-fetch.
"""

import json
from pathlib import Path
from itertools import groupby

# ──────────── Config ────────────
PASSES = [
    ("local", "dioula", "french"),
    ("local", "bambara", "french"),
    ("french", "french", "dioula"),
    ("french", "french", "bambara"),
]
OUTPUT = "evaluate.html"
EVAL_FILE = "results/evaluations.json"

GH_USER = "teaching-formation"
GH_REPO = "cahier-recette-lam-s2s"
GH_BRANCH = "main"
RAW_BASE = f"https://github.com/{GH_USER}/{GH_REPO}/raw/{GH_BRANCH}"
EVAL_JSON_URL = f"{RAW_BASE}/results/evaluations.json"

# ──────────── Collecte ────────────
rows = []

for src_folder, src_lang, tgt_lang in PASSES:
    persons_dir = Path(f"sources/{src_folder}")
    if not persons_dir.exists():
        continue

    for person_path in sorted(persons_dir.glob("person*")):
        if not person_path.is_dir():
            continue
        person = person_path.name

        for mp3 in sorted(person_path.glob("*.mp3")):
            name = mp3.stem
            json_path = Path(f"results/{src_lang}-to-{tgt_lang}/{person}/{name}.json")
            trad_audio_path = Path(f"results/{src_lang}-to-{tgt_lang}/{person}/{name}_translated.mp3")

            translation = "(non traité)"
            if json_path.exists():
                try:
                    data = json.loads(json_path.read_text())
                    translation = data.get("translation", "(vide)")
                except Exception:
                    translation = "(erreur JSON)"

            src_url = f"{RAW_BASE}/sources/{src_folder}/{person}/{name}.mp3"
            trad_url = f"{RAW_BASE}/results/{src_lang}-to-{tgt_lang}/{person}/{name}_translated.mp3" if trad_audio_path.exists() else ""

            eval_id = f"{src_lang}-to-{tgt_lang}|{person}|{name}"

            rows.append({
                "id": eval_id,
                "passe": f"{src_lang} → {tgt_lang}",
                "person": person,
                "name": name,
                "src_url": src_url,
                "trad_url": trad_url,
                "translation": translation,
            })

existing_evals = {}
if Path(EVAL_FILE).exists():
    try:
        existing_evals = json.loads(Path(EVAL_FILE).read_text())
    except Exception:
        pass

# ──────────── HTML ────────────
html = f"""<!DOCTYPE html>
<html lang="fr">
<head>
<meta charset="UTF-8">
<title>Évaluation — Recette LAM Speech-to-Speech</title>
<style>
  :root {{
    --blue: #004A9F;
    --orange: #F47920;
    --gray: #F2F2F2;
    --green: #1F7A4D;
    --red: #C00000;
    --yellow: #E0A800;
  }}
  * {{ box-sizing: border-box; }}
  body {{
    font-family: -apple-system, BlinkMacSystemFont, 'Helvetica Neue', Arial, sans-serif;
    margin: 0; padding: 0;
    background: #fafafa;
    color: #222;
  }}
  header {{
    position: sticky; top: 0; z-index: 100;
    background: white;
    border-bottom: 2px solid var(--orange);
    padding: 16px 24px;
    box-shadow: 0 2px 4px rgba(0,0,0,0.04);
  }}
  h1 {{ margin: 0; font-size: 20px; color: var(--blue); }}
  .subtitle {{ color: #666; font-size: 13px; margin-top: 4px; }}

  .toolbar {{
    display: flex; gap: 20px; align-items: center; flex-wrap: wrap;
    margin-top: 12px; font-size: 13px;
  }}
  .stat {{
    display: flex; align-items: center; gap: 6px;
    padding: 4px 10px; border-radius: 4px;
    background: var(--gray);
    font-weight: 500;
  }}
  .stat.exact {{ background: #e6f4ea; color: var(--green); }}
  .stat.fautes {{ background: #fff4e0; color: var(--yellow); }}
  .stat.hallu {{ background: #fbe9e9; color: var(--red); }}

  .action-btn {{
    padding: 6px 14px; border-radius: 6px;
    background: var(--blue); color: white;
    border: none; cursor: pointer;
    font-size: 13px; font-weight: 500;
  }}
  .action-btn:hover {{ background: #003d87; }}
  .action-btn.secondary {{ background: #666; }}
  .action-btn.secondary:hover {{ background: #444; }}

  main {{ padding: 24px; max-width: 1400px; margin: 0 auto; }}
  h2 {{
    color: var(--blue);
    margin-top: 32px; margin-bottom: 8px;
    padding-bottom: 6px;
    border-bottom: 1px solid #ddd;
    font-size: 18px;
  }}

  table {{
    width: 100%; border-collapse: collapse;
    background: white;
    box-shadow: 0 1px 3px rgba(0,0,0,0.05);
    font-size: 14px; margin-bottom: 16px;
  }}
  th {{
    background: var(--blue); color: white;
    padding: 10px 8px; text-align: left;
    font-weight: 600; font-size: 12px;
    letter-spacing: 0.3px;
  }}
  td {{
    padding: 10px 8px;
    border-top: 1px solid #eee;
    vertical-align: middle;
  }}
  tr:nth-child(even) td {{ background: #fafafa; }}
  tr.evaluated.exact td {{ background: #f0f8f4; }}
  tr.evaluated.fautes td {{ background: #fef8eb; }}
  tr.evaluated.hallu td {{ background: #fcf0f0; }}

  .name-col {{ font-family: ui-monospace, monospace; font-size: 11px; color: #555; width: 180px; }}
  .trad-col {{ max-width: 400px; line-height: 1.4; }}
  .actions-col {{ width: 280px; }}

  audio {{ height: 32px; width: 180px; }}

  .btn-group {{ display: flex; gap: 4px; }}
  .btn {{
    cursor: pointer;
    border: 1.5px solid #ddd;
    background: white;
    padding: 6px 10px;
    border-radius: 6px;
    font-size: 13px; font-weight: 600;
    color: #666;
    transition: transform 0.1s;
  }}
  .btn:hover {{ transform: translateY(-1px); box-shadow: 0 2px 4px rgba(0,0,0,0.1); }}
  .btn.active.exact {{ background: var(--green); color: white; border-color: var(--green); }}
  .btn.active.fautes {{ background: var(--yellow); color: white; border-color: var(--yellow); }}
  .btn.active.hallu {{ background: var(--red); color: white; border-color: var(--red); }}
  .btn.clear {{ color: #aaa; }}

  .comment {{
    width: 100%;
    border: 1px solid #ddd;
    border-radius: 4px;
    padding: 6px 8px;
    font-size: 12px;
    font-family: inherit;
    margin-top: 4px;
    resize: vertical;
    min-height: 28px; max-height: 80px;
  }}
  .comment:focus {{ outline: none; border-color: var(--blue); }}

  .help {{
    background: #fff9e6;
    border-left: 3px solid var(--orange);
    padding: 12px 16px;
    margin-bottom: 24px;
    font-size: 13px; line-height: 1.6;
    border-radius: 4px;
  }}
  .help kbd {{
    display: inline-block;
    background: white; border: 1px solid #ccc;
    border-radius: 3px;
    padding: 1px 6px;
    font-family: ui-monospace, monospace;
    font-size: 11px;
    box-shadow: 0 1px 0 rgba(0,0,0,0.1);
  }}

  .toast {{
    position: fixed; bottom: 20px; right: 20px;
    background: var(--green); color: white;
    padding: 14px 20px; border-radius: 8px;
    box-shadow: 0 4px 12px rgba(0,0,0,0.2);
    font-size: 13px; font-weight: 500;
    opacity: 0; transform: translateY(10px);
    transition: all 0.3s;
    pointer-events: none;
    max-width: 320px;
  }}
  .toast.show {{ opacity: 1; transform: translateY(0); }}
</style>
</head>
<body>

<header>
  <h1>📊 Cahier de recette — Évaluation des traductions LAM</h1>
  <div class="subtitle">ANSUT / DTDI · Noter chaque traduction en écoutant les audios</div>
  <div class="toolbar">
    <span class="stat"><span id="total">0</span> au total</span>
    <span class="stat exact">✅ <span id="count-exact">0</span></span>
    <span class="stat fautes">🟡 <span id="count-fautes">0</span></span>
    <span class="stat hallu">❌ <span id="count-hallu">0</span></span>
    <span class="stat">⏳ <span id="count-pending">0</span></span>

    <input type="file" id="import-file" accept=".json" style="display:none" onchange="importJSON(event)">
    <button class="action-btn secondary" onclick="document.getElementById('import-file').click()">📂 Importer</button>
    <button class="action-btn" onclick="exportEvaluations()">💾 Exporter JSON</button>
  </div>
</header>

<main>

<div class="help">
  <strong>Comment noter :</strong> écoute 🎙 (source), écoute 🔊 (traduction), clique sur le bon bouton.
  <br><strong>Raccourcis clavier</strong> : <kbd>1</kbd>=✅ · <kbd>2</kbd>=🟡 · <kbd>3</kbd>=❌ · <kbd>0</kbd>=effacer (après avoir cliqué sur une ligne).
  <br><strong>Sauvegarde</strong> : auto dans le navigateur. Pour persister côté projet : <strong>💾 Exporter</strong> → place <code>evaluations.json</code> dans <code>results/</code> → <code>./run.sh</code>.
  <br><strong>Reprendre</strong> : au chargement, la page tente de récupérer automatiquement les évaluations sur GitHub. Sinon, clique <strong>📂 Importer</strong>.
</div>

"""

for passe, pass_rows in groupby(rows, key=lambda r: r["passe"]):
    pass_rows = list(pass_rows)
    html += f'<h2>{passe}</h2>\n'

    for person, person_rows in groupby(pass_rows, key=lambda r: r["person"]):
        person_rows = list(person_rows)
        html += f'<h3 style="margin-top:16px;color:#555;font-size:15px">{person}</h3>\n<table>\n'
        html += '<tr><th>Fichier</th><th>Source</th><th>Traduction</th><th>Audio trad.</th><th>Évaluation</th></tr>\n'

        for row in person_rows:
            rid = row["id"]
            existing = existing_evals.get(rid, {})
            tag = existing.get("tag", "")
            comment = existing.get("comment", "")

            row_class = f"evaluated {tag}" if tag else ""

            def esc(s):
                return (s.replace("&", "&amp;")
                         .replace("<", "&lt;")
                         .replace(">", "&gt;")
                         .replace('"', "&quot;"))

            trad_escaped = esc(row["translation"])
            comment_escaped = esc(comment)
            trad_audio_cell = f'<audio controls preload="none" src="{row["trad_url"]}"></audio>' if row["trad_url"] else '<em>—</em>'

            html += f'''<tr class="{row_class}" data-id="{rid}" tabindex="0">
  <td class="name-col">{row["name"]}</td>
  <td><audio controls preload="none" src="{row["src_url"]}"></audio></td>
  <td class="trad-col">{trad_escaped}</td>
  <td>{trad_audio_cell}</td>
  <td class="actions-col">
    <div class="btn-group">
      <button class="btn exact {'active' if tag=='exact' else ''}" data-tag="exact">✅</button>
      <button class="btn fautes {'active' if tag=='fautes' else ''}" data-tag="fautes">🟡</button>
      <button class="btn hallu {'active' if tag=='hallu' else ''}" data-tag="hallu">❌</button>
      <button class="btn clear" data-tag="">✕</button>
    </div>
    <textarea class="comment" placeholder="commentaire (optionnel)">{comment_escaped}</textarea>
  </td>
</tr>\n'''

        html += '</table>\n'

html += f"""

<div class="toast" id="toast"></div>

</main>

<script>
const STORAGE_KEY = 'lam_evaluations_v1';
const REMOTE_EVAL_URL = '{EVAL_JSON_URL}';

function getEvals() {{
  return JSON.parse(localStorage.getItem(STORAGE_KEY) || '{{}}');
}}
function saveEvals(evals) {{
  localStorage.setItem(STORAGE_KEY, JSON.stringify(evals));
  updateStats();
}}
function showToast(msg, isError) {{
  const t = document.getElementById('toast');
  t.textContent = msg;
  t.style.background = isError ? 'var(--red)' : 'var(--green)';
  t.classList.add('show');
  setTimeout(() => t.classList.remove('show'), 3000);
}}

function applyEvalsToUI(evals) {{
  document.querySelectorAll('tr[data-id]').forEach(tr => {{
    const id = tr.dataset.id;
    const entry = evals[id] || {{}};
    const tag = entry.tag || '';
    const comment = entry.comment || '';

    tr.querySelectorAll('.btn').forEach(b => {{
      if (b.dataset.tag === tag && tag !== '') b.classList.add('active');
      else b.classList.remove('active');
    }});

    tr.classList.remove('evaluated', 'exact', 'fautes', 'hallu');
    if (tag) tr.classList.add('evaluated', tag);

    const commentEl = tr.querySelector('.comment');
    if (commentEl) commentEl.value = comment;
  }});
  updateStats();
}}

document.addEventListener('DOMContentLoaded', async () => {{
  updateStats();

  try {{
    const response = await fetch(REMOTE_EVAL_URL + '?t=' + Date.now());
    if (response.ok) {{
      const remoteEvals = await response.json();
      const localEvals = getEvals();
      const merged = Object.assign({{}}, remoteEvals, localEvals);
      saveEvals(merged);
      applyEvalsToUI(merged);

      const remoteCount = Object.keys(remoteEvals).length;
      const localCount = Object.keys(localEvals).length;
      if (remoteCount > 0 || localCount > 0) {{
        showToast(`✓ ${{remoteCount}} distantes + ${{localCount}} locales chargées`);
      }}
    }}
  }} catch (e) {{
    console.log('Pas de evaluations.json distant, utilisation locale uniquement');
  }}
}});

document.addEventListener('click', (e) => {{
  const btn = e.target.closest('.btn');
  if (!btn) return;
  const tr = btn.closest('tr[data-id]');
  if (!tr) return;

  const id = tr.dataset.id;
  const tag = btn.dataset.tag;
  const evals = getEvals();

  tr.querySelectorAll('.btn').forEach(b => {{
    if (b.dataset.tag === tag && tag !== '') b.classList.add('active');
    else b.classList.remove('active');
  }});

  tr.classList.remove('evaluated', 'exact', 'fautes', 'hallu');
  if (tag) {{
    tr.classList.add('evaluated', tag);
    evals[id] = evals[id] || {{}};
    evals[id].tag = tag;
  }} else {{
    if (evals[id]) {{
      delete evals[id].tag;
      if (!evals[id].comment) delete evals[id];
    }}
  }}

  saveEvals(evals);
}});

document.addEventListener('input', (e) => {{
  if (!e.target.classList.contains('comment')) return;
  const tr = e.target.closest('tr[data-id]');
  if (!tr) return;
  const id = tr.dataset.id;
  const evals = getEvals();
  evals[id] = evals[id] || {{}};
  evals[id].comment = e.target.value;
  if (!evals[id].comment && !evals[id].tag) delete evals[id];
  saveEvals(evals);
}});

document.addEventListener('keydown', (e) => {{
  if (e.target.tagName === 'TEXTAREA') return;
  const tr = document.activeElement?.closest?.('tr[data-id]');
  if (!tr) return;

  const tagMap = {{'1': 'exact', '2': 'fautes', '3': 'hallu', '0': ''}};
  if (e.key in tagMap) {{
    e.preventDefault();
    const btn = tr.querySelector(`.btn[data-tag="${{tagMap[e.key]}}"]`);
    if (btn) btn.click();
  }}
}});

function updateStats() {{
  const evals = getEvals();
  let exact = 0, fautes = 0, hallu = 0;
  Object.values(evals).forEach(e => {{
    if (e.tag === 'exact') exact++;
    else if (e.tag === 'fautes') fautes++;
    else if (e.tag === 'hallu') hallu++;
  }});
  const total = document.querySelectorAll('tr[data-id]').length;
  const pending = total - exact - fautes - hallu;

  document.getElementById('total').textContent = total;
  document.getElementById('count-exact').textContent = exact;
  document.getElementById('count-fautes').textContent = fautes;
  document.getElementById('count-hallu').textContent = hallu;
  document.getElementById('count-pending').textContent = pending;
}}

function exportEvaluations() {{
  const evals = getEvals();
  const blob = new Blob([JSON.stringify(evals, null, 2)], {{type: 'application/json'}});
  const url = URL.createObjectURL(blob);
  const a = document.createElement('a');
  a.href = url;
  a.download = 'evaluations.json';
  a.click();
  URL.revokeObjectURL(url);
  showToast('✓ evaluations.json téléchargé — place-le dans results/ puis lance ./run.sh');
}}

function importJSON(event) {{
  const file = event.target.files[0];
  if (!file) return;
  const reader = new FileReader();
  reader.onload = (e) => {{
    try {{
      const imported = JSON.parse(e.target.result);
      const current = getEvals();
      const merged = Object.assign({{}}, current, imported);
      saveEvals(merged);
      applyEvalsToUI(merged);
      showToast(`✓ ${{Object.keys(imported).length}} évaluation(s) importée(s)`);
    }} catch (err) {{
      showToast('❌ Fichier JSON invalide', true);
    }}
  }};
  reader.readAsText(file);
  event.target.value = '';
}}
</script>

</body>
</html>
"""

Path(OUTPUT).write_text(html)
print(f"✅ {OUTPUT} généré avec {len(rows)} évaluations")
print(f"   URL GitHub Pages : https://{GH_USER}.github.io/{GH_REPO}/{OUTPUT}")
