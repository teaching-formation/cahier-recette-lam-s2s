# Cahier de recette — API Speech-to-Speech LAM

**Prestataire** : LAfricaMobile
**Client** : ANSUT / DTDI
**Sens de traduction** : `dioula` → `french`
**Généré le** : 2026-04-20 à 11:56:37

---

## person1

| Fichier | Source (wav) | Traduction (texte) | Audio traduit (wav) | Statut |
|---|---|---|---|---|
| AUDIO-2026-04-20-10-16-09 | [🎙](https://raw.githubusercontent.com/teaching-formation/cahier-recette-lam-s2s/main/person1/AUDIO-2026-04-20-10-16-09.wav) | í ni sùnggoma, á&#39; be dí ? fondation en carrelage ?  | [🔊](https://raw.githubusercontent.com/teaching-formation/cahier-recette-lam-s2s/main/results/person1/AUDIO-2026-04-20-10-16-09_translated.wav) | ✅ |
| AUDIO-2026-04-20-10-16-32 | [🎙](https://raw.githubusercontent.com/teaching-formation/cahier-recette-lam-s2s/main/person1/AUDIO-2026-04-20-10-16-32.wav) | Tu as attrapé ses six poissons d'un seul coup.  | [🔊](https://raw.githubusercontent.com/teaching-formation/cahier-recette-lam-s2s/main/results/person1/AUDIO-2026-04-20-10-16-32_translated.wav) | ✅ |
| AUDIO-2026-04-20-10-16-58 | [🎙](https://raw.githubusercontent.com/teaching-formation/cahier-recette-lam-s2s/main/person1/AUDIO-2026-04-20-10-16-58.wav) | J&#39;en cherche quelques-uns, je ne trouve personne là-bas, et vous ?  | [🔊](https://raw.githubusercontent.com/teaching-formation/cahier-recette-lam-s2s/main/results/person1/AUDIO-2026-04-20-10-16-58_translated.wav) | ✅ |
| AUDIO-2026-04-20-10-17-22 | [🎙](https://raw.githubusercontent.com/teaching-formation/cahier-recette-lam-s2s/main/person1/AUDIO-2026-04-20-10-17-22.wav) | S&#39;il ne te fait pas de mal, n'est-ce pas toi qui as des problèmes ?  | [🔊](https://raw.githubusercontent.com/teaching-formation/cahier-recette-lam-s2s/main/results/person1/AUDIO-2026-04-20-10-17-22_translated.wav) | ✅ |

## person2

| Fichier | Source (wav) | Traduction (texte) | Audio traduit (wav) | Statut |
|---|---|---|---|---|
| AUDIO-2026-04-20-11-11-35 | [🎙](https://raw.githubusercontent.com/teaching-formation/cahier-recette-lam-s2s/main/person2/AUDIO-2026-04-20-11-11-35.wav) | Il est trop tard, mais ce n'est pas impossible.  | [🔊](https://raw.githubusercontent.com/teaching-formation/cahier-recette-lam-s2s/main/results/person2/AUDIO-2026-04-20-11-11-35_translated.wav) | ✅ |
| AUDIO-2026-04-20-11-14-21 | [🎙](https://raw.githubusercontent.com/teaching-formation/cahier-recette-lam-s2s/main/person2/AUDIO-2026-04-20-11-14-21.wav) | Aujourd'hui, le soleil s'est levé,  | [🔊](https://raw.githubusercontent.com/teaching-formation/cahier-recette-lam-s2s/main/results/person2/AUDIO-2026-04-20-11-14-21_translated.wav) | ✅ |
| AUDIO-2026-04-20-11-14-35 | [🎙](https://raw.githubusercontent.com/teaching-formation/cahier-recette-lam-s2s/main/person2/AUDIO-2026-04-20-11-14-35.wav) | Dieu nous a permis d'accepter le poison du maïs !  | [🔊](https://raw.githubusercontent.com/teaching-formation/cahier-recette-lam-s2s/main/results/person2/AUDIO-2026-04-20-11-14-35_translated.wav) | ✅ |
| AUDIO-2026-04-20-11-15-14 | [🎙](https://raw.githubusercontent.com/teaching-formation/cahier-recette-lam-s2s/main/person2/AUDIO-2026-04-20-11-15-14.wav) | L&#39;homme est poussière, et nous sommes tous poussière.  | [🔊](https://raw.githubusercontent.com/teaching-formation/cahier-recette-lam-s2s/main/results/person2/AUDIO-2026-04-20-11-15-14_translated.wav) | ✅ |
| AUDIO-2026-04-20-11-15-31 | [🎙](https://raw.githubusercontent.com/teaching-formation/cahier-recette-lam-s2s/main/person2/AUDIO-2026-04-20-11-15-31.wav) | n'ála k&#39;í sòn, ê ka gwaa so, n'ála mîn sòn kà nà ŋími sà.  | [🔊](https://raw.githubusercontent.com/teaching-formation/cahier-recette-lam-s2s/main/results/person2/AUDIO-2026-04-20-11-15-31_translated.wav) | ✅ |

## person3

| Fichier | Source (wav) | Traduction (texte) | Audio traduit (wav) | Statut |
|---|---|---|---|---|
| AUDIO-2026-04-20-11-30-29 | [🎙](https://raw.githubusercontent.com/teaching-formation/cahier-recette-lam-s2s/main/person3/AUDIO-2026-04-20-11-30-29.wav) | et le matin, le matin, je suis allé à la maison !  | [🔊](https://raw.githubusercontent.com/teaching-formation/cahier-recette-lam-s2s/main/results/person3/AUDIO-2026-04-20-11-30-29_translated.wav) | ✅ |

---

## Bilan de cette exécution

- **Total d'appels API** : 0
- **Succès** : 0
- **Échecs** : 0

## Notes techniques

- **Endpoint** : `POST /translate-audio`
- **Format d'entrée accepté** : WAV 16 kHz mono PCM 16-bit (les m4a natifs iPhone sont convertis via ffmpeg avant envoi — originaux conservés en local dans `_originaux/`)
- **Codes langue supportés** : `bambara`, `dioula`, `french`
- **MIME type requis** : `audio/wav`
