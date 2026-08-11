# Lumina Signal — Content Schema

## Objectif

Définir la structure des contenus (vidéos + épisodes podcast) qui alimenteront le Feed.

---

## Content Object

```json
{
  "id": "string",
  "voiceId": "string",
  "type": "video | podcast",
  "title": "string",
  "titleFr": "string | null",
  "description": "string",
  "descriptionFr": "string | null",
  "url": "string",
  "thumbnail": "string | null",
  "durationSeconds": 0,
  "publishedAt": "2026-08-10T14:30:00Z",
  "platform": "youtube | spotify | apple | other",
  "signalScore": 8.7,
  "topics": ["agents", "safety", "evals"],
  "language": "en",
  "isNew": true
}
```

---

## Champs clés

| Champ | Description |
|-------|-------------|
| `voiceId` | Lien vers la voix (ex: `dwarkesh-patel`) |
| `type` | `video` ou `podcast` |
| `signalScore` | Score du contenu (peut différer du score de la voix) |
| `topics` | Tags libres pour le filtrage sémantique / Assistant |
| `language` | Langue principale du contenu |
| `isNew` | Flag calculé (publié < 72h) |

---

## Sources d’ingestion

1. **YouTube RSS**  
   `https://www.youtube.com/feeds/videos.xml?channel_id=CHANNEL_ID`

2. **Podcast RSS**  
   Flux standard (Apple / Spotify / site)

3. **Enrichissement manuel** (titres FR, topics, scores)

---

## Feed Logic

- Tri par défaut : `publishedAt` décroissant
- Filtres : type, catégorie de la voix, pays, langue, topics
- Watchlist : ne montre que les contenus des voix suivies
- Briefing du jour : top contenus des 24–72 dernières heures selon signalScore + recency

---

## Relation avec les Voix

```
Voice 1 ─── Content A
       └─── Content B
Voice 2 ─── Content C
```

Le Feed joint les deux collections.

---

## Phase d’implémentation

1. **Maintenant** : schéma figé
2. **Ensuite** : quelques contenus d’exemple en dur dans le prototype v3
3. **Puis** : robot RSS (GitHub Action) qui produit un `contents.json`
4. **Enfin** : base de données si le volume le justifie

---

*Schéma vivant — pourra évoluer légèrement avec les premiers tests.*
