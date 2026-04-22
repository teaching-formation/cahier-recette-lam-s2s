#!/bin/bash
set -e

# ══════════════════════════════════════════════
#  Recette API Speech-to-Speech LAM × ANSUT
#  Tests bidirectionnels langues locales ↔ français
#  + Interface web d'évaluation (evaluate.html)
#  Compatible macOS Bash 3.2
# ══════════════════════════════════════════════

# ────────── Config ──────────
BASE="https://ansut-test.lafricamobile.com"
MAX_DURATION=25

PASSES=(
  "local:dioula:french"
  "local:bambara:french"
  "french:french:dioula"
  "french:french:bambara"
)

GH_USER="teaching-formation"
GH_REPO="cahier-recette-lam-s2s"
GH_BRANCH="main"
RAW_BASE="https://github.com/$GH_USER/$GH_REPO/raw/$GH_BRANCH"

BACKUP_DIR="_originaux"
SUMMARY="results/summary.md"
EVAL_FILE="results/evaluations.json"
mkdir -p results "$BACKUP_DIR" sources/local sources/french

if ! grep -q "^_originaux/" .gitignore 2>/dev/null; then
  echo "_originaux/" >> .gitignore
fi

list_persons() {
  local src_folder=$1
  ls -d "sources/$src_folder"/person*/ 2>/dev/null | \
    sed "s|sources/$src_folder/||" | sed 's|/||' | sort
}

echo "🌍 Passes à exécuter :"
for pass in "${PASSES[@]}"; do
  IFS=':' read -r SRC_FOLDER SRC_LANG TGT_LANG <<< "$pass"
  count=$(list_persons "$SRC_FOLDER" | wc -l | tr -d ' ')
  echo "   sources/$SRC_FOLDER/ · $SRC_LANG → $TGT_LANG ($count locuteurs)"
done
echo "⏱  Segment max : ${MAX_DURATION}s"

# ────────── Étape 0 : Nettoyage des noms de fichiers ──────────
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  0/6  Nettoyage des noms de fichiers (espaces → _)"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

RENAMED=0
for base_dir in sources results _originaux; do
  [ -d "$base_dir" ] || continue
  while IFS= read -r f; do
    newname=$(echo "$f" | sed 's/ /_/g')
    if [ "$f" != "$newname" ]; then
      if [ ! -e "$newname" ]; then
        echo "📝 $f → $newname"
        mv "$f" "$newname"
        RENAMED=$((RENAMED+1))
      fi
    fi
  done < <(find "$base_dir" -name "* *" 2>/dev/null)
done

[ $RENAMED -eq 0 ] && echo "ℹ  Tous les noms sont déjà propres" || echo "✅ $RENAMED renommage(s)"

# ────────── Étape 1 : Conversion m4a → mp3 ──────────
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  1/6  Conversion m4a → mp3"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

for src_folder in sources/*/; do
  folder_name=$(basename "$src_folder")
  for person_dir in "$src_folder"person*/; do
    [ -d "$person_dir" ] || continue
    person=$(basename "$person_dir")
    mkdir -p "$BACKUP_DIR/$folder_name/$person"

    shopt -s nullglob
    for f in "$person_dir"*.m4a; do
      mp3="${f%.m4a}.mp3"
      name=$(basename "$f")

      if [ ! -f "$BACKUP_DIR/$folder_name/$person/$name" ]; then
        cp "$f" "$BACKUP_DIR/$folder_name/$person/$name"
      fi

      if [ ! -f "$mp3" ]; then
        echo "🔄 $f → $mp3"
        ffmpeg -y -loglevel error -i "$f" -ar 16000 -ac 1 -c:a libmp3lame -b:a 64k "$mp3"
      fi

      if [ -s "$mp3" ]; then
        rm "$f"
      else
        rm -f "$mp3"
      fi
    done
    shopt -u nullglob
  done
done

# ────────── Étape 1bis : Découpage audios > MAX_DURATION ──────────
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  1bis/6  Découpage audios longs (> ${MAX_DURATION}s)"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

for src_folder in sources/*/; do
  for person_dir in "$src_folder"person*/; do
    [ -d "$person_dir" ] || continue

    shopt -s nullglob
    for f in "$person_dir"*.mp3; do
      name=$(basename "$f" .mp3)
      [[ "$name" == *_part* ]] && continue

      duration=$(ffprobe -v error -show_entries format=duration -of csv=p=0 "$f" 2>/dev/null)
      duration_int=${duration%.*}
      [ -z "$duration_int" ] || [ "$duration_int" -lt "$MAX_DURATION" ] && continue

      shopt -s nullglob
      EXISTING=("$person_dir${name}_part"*.mp3)
      shopt -u nullglob
      [ ${#EXISTING[@]} -gt 0 ] && { echo "⏭  $f déjà découpé"; continue; }

      echo "✂  $f (${duration_int}s) → segments"
      ffmpeg -y -loglevel error -i "$f" \
        -f segment -segment_time "$MAX_DURATION" \
        -c:a libmp3lame -b:a 64k -ar 16000 -ac 1 \
        "$person_dir${name}_part%03d.mp3"

      shopt -s nullglob
      CREATED=("$person_dir${name}_part"*.mp3)
      shopt -u nullglob
      [ ${#CREATED[@]} -gt 0 ] && rm "$f"
    done
    shopt -u nullglob
  done
done

# ────────── Étape 2 : Appels API ──────────
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  2/6  Appels API LAM"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

TOTAL=0; SUCCESS=0; FAIL=0

for pass in "${PASSES[@]}"; do
  IFS=':' read -r SRC_FOLDER SRC_LANG TGT_LANG <<< "$pass"
  echo ""
  echo "══ Passe : $SRC_LANG → $TGT_LANG ══"

  PERSONS=($(list_persons "$SRC_FOLDER"))
  [ ${#PERSONS[@]} -eq 0 ] && { echo "   (vide)"; continue; }

  for person in "${PERSONS[@]}"; do
    OUT_DIR="results/$SRC_LANG-to-$TGT_LANG/$person"
    mkdir -p "$OUT_DIR"

    shopt -s nullglob
    MP3S=("sources/$SRC_FOLDER/$person"/*.mp3)
    shopt -u nullglob

    for f in "${MP3S[@]}"; do
      name=$(basename "$f" .mp3)

      if [ -f "$OUT_DIR/${name}.json" ] && [ -f "$OUT_DIR/${name}_translated.mp3" ]; then
        echo "⏭  $SRC_LANG-to-$TGT_LANG/$person/$name"
        continue
      fi

      TOTAL=$((TOTAL+1))
      echo "▶ $SRC_LANG-to-$TGT_LANG/$person/$name"

      tmp_wav="/tmp/${name}_${SRC_LANG}_${TGT_LANG}.wav"
      ffmpeg -y -loglevel error -i "$f" -ar 16000 -ac 1 -c:a pcm_s16le "$tmp_wav"

      RESP=$(curl -sS -w "\n__HTTP__%{http_code}__TIME__%{time_total}" \
        -X POST "$BASE/translate-audio?from_lang=$SRC_LANG&to_lang=$TGT_LANG" \
        -F "audio=@$tmp_wav;type=audio/wav")

      HTTP=$(echo "$RESP" | grep -o '__HTTP__[0-9]*' | cut -d_ -f5)
      TIME=$(echo "$RESP" | grep -o '__TIME__[0-9.]*' | cut -d_ -f5)
      BODY=$(echo "$RESP" | sed 's/__HTTP__.*//')

      if [ "$HTTP" = "200" ]; then
        SUCCESS=$((SUCCESS+1))
        echo "$BODY" > "$OUT_DIR/${name}.json"
        PATH_AUDIO=$(echo "$BODY" | jq -r '.path_to_audio')

        tmp_trad="/tmp/${name}_${SRC_LANG}_${TGT_LANG}_trad.wav"
        if [[ "$PATH_AUDIO" == http* ]]; then
          curl -sS -o "$tmp_trad" "$PATH_AUDIO"
        else
          curl -sS -o "$tmp_trad" "$BASE$PATH_AUDIO"
        fi

        ffmpeg -y -loglevel error -i "$tmp_trad" -ar 16000 -ac 1 -c:a libmp3lame -b:a 64k "$OUT_DIR/${name}_translated.mp3"
        rm -f "$tmp_trad"
        rm -f "$OUT_DIR/${name}.error.json"
        echo "  ✅ HTTP 200 · ${TIME}s"
      else
        FAIL=$((FAIL+1))
        echo "$BODY" > "$OUT_DIR/${name}.error.json"
        echo "  ❌ HTTP $HTTP · ${TIME}s"
      fi

      rm -f "$tmp_wav"
    done
  done
done

# ────────── Étape 3 : Génération de evaluate.html ──────────
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  3/6  Génération de l'interface d'évaluation"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

if [ -f build_evaluate.py ]; then
  python3 build_evaluate.py
else
  echo "⚠️  build_evaluate.py introuvable, étape sautée"
fi

# ────────── Étape 4 : Génération summary.md ──────────
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  4/6  Génération summary.md (avec évaluations)"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# Fonction : lit l'évaluation depuis evaluations.json pour une clé donnée
# Utilise python pour parser le JSON proprement (jq serait aussi possible)
get_eval_tag() {
  local key=$1
  [ ! -f "$EVAL_FILE" ] && { echo ""; return; }
  python3 -c "
import json, sys
try:
    data = json.load(open('$EVAL_FILE'))
    entry = data.get('$key', {})
    tag = entry.get('tag', '')
    tag_map = {'exact': '✅ Sens exact', 'fautes': '🟡 Fautes visibles', 'hallu': '❌ Hallucination'}
    print(tag_map.get(tag, ''))
except Exception:
    print('')
" 2>/dev/null
}

get_eval_comment() {
  local key=$1
  [ ! -f "$EVAL_FILE" ] && { echo ""; return; }
  python3 -c "
import json, sys
try:
    data = json.load(open('$EVAL_FILE'))
    entry = data.get('$key', {})
    print(entry.get('comment', '').replace('|', '/').replace('\n', ' '))
except Exception:
    print('')
" 2>/dev/null
}

# Compteurs
TOT_ROWS=0; TOT_EXACT=0; TOT_FAUTES=0; TOT_HALLU=0; TOT_NON_EVAL=0

cat > "$SUMMARY" <<EOF
# Cahier de recette — API Speech-to-Speech LAM

**Prestataire** : LAfricaMobile
**Client** : ANSUT / DTDI
**Tests bidirectionnels** : dioula ↔ français · bambara ↔ français
**Généré le** : $(date '+%Y-%m-%d à %H:%M:%S')

---

## 📝 Comment évaluer

Ouvre \`evaluate.html\` dans ton navigateur, écoute les audios, clique sur les boutons ✅ / 🟡 / ❌. Puis clique sur "💾 Exporter" en bas à droite, place le \`evaluations.json\` téléchargé dans le dossier \`results/\`, et relance \`./run.sh\`.

| Tag | Signification |
|---|---|
| ✅ Sens exact | Traduction fidèle et utilisable |
| 🟡 Fautes visibles | Compréhensible mais qualité moyenne |
| ❌ Hallucination | Contresens ou invention de contenu |

---

EOF

for pass in "${PASSES[@]}"; do
  IFS=':' read -r SRC_FOLDER SRC_LANG TGT_LANG <<< "$pass"
  PERSONS=($(list_persons "$SRC_FOLDER"))

  echo "# Passe : $SRC_LANG → $TGT_LANG" >> "$SUMMARY"
  echo "" >> "$SUMMARY"

  if [ ${#PERSONS[@]} -eq 0 ]; then
    echo "_(aucun audio source)_" >> "$SUMMARY"
    echo "" >> "$SUMMARY"
    echo "---" >> "$SUMMARY"
    echo "" >> "$SUMMARY"
    continue
  fi

  for person in "${PERSONS[@]}"; do
    shopt -s nullglob
    MP3S=("sources/$SRC_FOLDER/$person"/*.mp3)
    shopt -u nullglob

    echo "## $person" >> "$SUMMARY"
    echo "" >> "$SUMMARY"

    if [ ${#MP3S[@]} -eq 0 ]; then
      echo "_(aucun fichier)_" >> "$SUMMARY"
      echo "" >> "$SUMMARY"
      continue
    fi

    echo "| Fichier | Source | Traduction ($TGT_LANG) | Audio traduit | Évaluation |" >> "$SUMMARY"
    echo "|---|---|---|---|---|" >> "$SUMMARY"

    for f in "${MP3S[@]}"; do
      name=$(basename "$f" .mp3)
      SRC_URL="$RAW_BASE/sources/$SRC_FOLDER/$person/${name}.mp3"
      TRAD_URL="$RAW_BASE/results/$SRC_LANG-to-$TGT_LANG/$person/${name}_translated.mp3"
      JSON="results/$SRC_LANG-to-$TGT_LANG/$person/${name}.json"

      eval_key="${SRC_LANG}-to-${TGT_LANG}|${person}|${name}"
      tag=$(get_eval_tag "$eval_key")
      comment=$(get_eval_comment "$eval_key")

      eval_cell="$tag"
      [ -n "$comment" ] && eval_cell="$tag — $comment"

      TOT_ROWS=$((TOT_ROWS+1))
      case "$tag" in
        *"✅"*) TOT_EXACT=$((TOT_EXACT+1)) ;;
        *"🟡"*) TOT_FAUTES=$((TOT_FAUTES+1)) ;;
        *"❌"*) TOT_HALLU=$((TOT_HALLU+1)) ;;
        *) TOT_NON_EVAL=$((TOT_NON_EVAL+1)) ;;
      esac

      if [ -f "$JSON" ]; then
        TRANSLATION=$(jq -r '.translation' "$JSON" | sed 's/|/\\|/g' | tr '\n' ' ')
        echo "| $name | [🎙]($SRC_URL) | $TRANSLATION | [🔊]($TRAD_URL) | $eval_cell |" >> "$SUMMARY"
      else
        echo "| $name | [🎙]($SRC_URL) | _(non traité)_ | — | $eval_cell |" >> "$SUMMARY"
      fi
    done
    echo "" >> "$SUMMARY"
  done

  echo "---" >> "$SUMMARY"
  echo "" >> "$SUMMARY"
done

# Calcul des pourcentages et verdict
if [ $TOT_ROWS -gt 0 ]; then
  pct_exact=$(( TOT_EXACT * 100 / TOT_ROWS ))
  pct_fautes=$(( TOT_FAUTES * 100 / TOT_ROWS ))
  pct_hallu=$(( TOT_HALLU * 100 / TOT_ROWS ))
  pct_non_eval=$(( TOT_NON_EVAL * 100 / TOT_ROWS ))
  evaluated=$(( TOT_ROWS - TOT_NON_EVAL ))

  if [ $evaluated -gt 0 ]; then
    pct_exact_of_eval=$(( TOT_EXACT * 100 / evaluated ))
    if [ $pct_exact_of_eval -ge 80 ]; then
      verdict="✅ Prêt pour la production"
    elif [ $pct_exact_of_eval -ge 60 ]; then
      verdict="🟡 Exploitable avec vigilance"
    elif [ $pct_exact_of_eval -ge 30 ]; then
      verdict="🟠 Non exploitable en l'état"
    else
      verdict="🔴 Non conforme"
    fi
  else
    verdict="⏳ Évaluation à faire (ouvrir evaluate.html)"
  fi
fi

cat >> "$SUMMARY" <<EOF

## 📊 Bilan qualité

- ✅ **Sens exact** : $TOT_EXACT / $TOT_ROWS ($pct_exact%)
- 🟡 **Fautes visibles** : $TOT_FAUTES / $TOT_ROWS ($pct_fautes%)
- ❌ **Hallucination** : $TOT_HALLU / $TOT_ROWS ($pct_hallu%)
- ⏳ **Non évalué** : $TOT_NON_EVAL / $TOT_ROWS ($pct_non_eval%)

**Verdict global** : $verdict

---

## 🔧 Exécution

- **Appels API (ce run)** : $TOTAL · Succès $SUCCESS · Échecs $FAIL

## Notes techniques

- **Endpoint** : \`POST /translate-audio\`
- **Format d'entrée** : WAV 16 kHz mono PCM 16-bit
- **Codes langue** : \`bambara\`, \`dioula\`, \`french\`
- **Durée max** : 30s — segmentation auto au-delà
- **Méthodologie** : tests bidirectionnels — les audios en langue locale (\`sources/local/\`) sont évalués en \`dioula\` ET en \`bambara\`.
EOF

echo "📄 $SUMMARY ($TOT_EXACT ✅ / $TOT_FAUTES 🟡 / $TOT_HALLU ❌ / $TOT_NON_EVAL ⏳)"

# ────────── Étape 5 : DOCX ──────────
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  5/6  Génération DOCX"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
if [ -f generate_docx.js ]; then
  node generate_docx.js
else
  echo "⚠️  generate_docx.js introuvable, étape sautée"
fi

# ────────── Étape 6 : Push Git ──────────
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  6/6  Push sur GitHub"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

git add .gitignore sources results evaluate.html 2>/dev/null || true
if git diff --cached --quiet; then
  echo "ℹ  Rien de nouveau à commiter"
else
  git commit -m "Recette $(date '+%Y-%m-%d %H:%M') — $SUCCESS ok / $FAIL ko · éval $TOT_EXACT✅ $TOT_FAUTES🟡 $TOT_HALLU❌"
  git push origin main
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "✅ Terminé"
echo "   📝 Évaluer     : ouvrir evaluate.html dans le navigateur"
echo "   📄 Résumé      : $SUMMARY"
echo "   📘 DOCX        : results/recette-lam.docx"
echo "   🌐 GitHub      : https://github.com/$GH_USER/$GH_REPO"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
