# Cahier de recette — API Speech-to-Speech LAfricaMobile

**Client** : ANSUT / DTDI
**Prestataire** : LAfricaMobile
**Chef de projet** : Youssouf Diakité

## 📌 Objet

Test de conformité de l'API de traduction Speech-to-Speech LAfricaMobile pour
intégration dans les projets DTDI de l'ANSUT (Kôman, Mon Toit, ConnectMyZone).

## 🔗 Liens utiles

- **📊 Interface d'évaluation** : [evaluate.html](https://teaching-formation.github.io/cahier-recette-lam-s2s/evaluate.html)
- **📄 Synthèse résultats** : [results/summary.md](results/summary.md)
- **📘 DOCX final** : [results/recette-lam.docx](results/recette-lam.docx)

## 🧪 Méthodologie

4 passes de tests bidirectionnels :
- `dioula → french` · `bambara → french` · `french → dioula` · `french → bambara`

Sur **6 locuteurs** (5 pour les audios français), **~25 audios** uniques,
soit **~90 appels API** avec évaluation qualitative en 3 catégories :
✅ Sens exact · 🟡 Fautes visibles · ❌ Hallucination

## 🛠 Stack technique

- `run.sh` : pipeline complet (conversion, découpage, API, push)
- `build_evaluate.py` : générateur de l'interface d'évaluation
- `generate_docx.js` : génération du livrable Word (police Tw Cen MT, couleurs ANSUT)
- Audio : m4a (source) → mp3 64 kbps (stockage) → wav (envoi API, contrainte LAM)

## 📋 Contraintes API identifiées

- Format exigé : WAV 16 kHz mono PCM 16-bit (pas de m4a/mp3 en entrée)
- Durée max par audio : **30 secondes** (segmentation auto au-delà)
- Codes langue : `bambara`, `dioula`, `french` (en toutes lettres, pas ISO 639)
- Endpoint : `POST /translate-audio` (avec tiret, pas underscore)
- Pas d'authentification en environnement TEST

## 📊 Résultats

Voir [results/summary.md](results/summary.md) pour le bilan complet et le verdict.