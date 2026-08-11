# Lumina Signal — RSS Ingestion Plan

## Objectif

Mettre à jour automatiquement le feed de contenus à partir des sources publiques des voix (YouTube + Podcasts).

---

## Sources prioritaires

### YouTube (via RSS)

Format standard :
```
https://www.youtube.com/feeds/videos.xml?channel_id=CHANNEL_ID
```

Exemples de chaînes prioritaires :
- Andrej Karpathy
- Dwarkesh Patel
- Yannic Kilcher
- AI Explained
- 3Blue1Brown
- Lex Fridman
- Nicolas Guyon (Comptoir IA)

### Podcasts (RSS classiques)

- Dwarkesh Podcast → disponible via dwarkesh.com
- Latent Space → latent.space
- The Cognitive Revolution → cognitiverevolution.ai
- TWIML AI Podcast
- Comptoir IA (Acast / Spotify)

---

## Architecture du robot

```
GitHub Action (cron quotidien ou toutes les 6h)
        ↓
Script Node.js / Python
        ↓
1. Lire la liste des sources (voices.json + sources.json)
2. Fetch RSS
3. Normaliser (title, date, url, duration si possible)
4. Dédupliquer
5. Enrichir légèrement (topics basiques, signalScore hérité de la voix)
6. Écrire contents.json
7. Commit + push (ou upload vers storage)
```

---

## Fichier sources (à créer)

```json
{
  "sources": [
    {
      "voiceId": "andrej-karpathy",
      "type": "youtube",
      "channelId": "...",
      "rss": "https://www.youtube.com/feeds/videos.xml?channel_id=..."
    },
    {
      "voiceId": "dwarkesh-patel",
      "type": "podcast",
      "rss": "https://..."
    }
  ]
}
```

---

## Règles

- Maximum ~20–30 sources actives au début (qualité > exhaustivité)
- Ne garder que les contenus des 30–60 derniers jours pour le feed principal
- SignalScore du contenu = SignalScore de la voix (au début)
- Topics : extraction simple par mots-clés ou plus tard via LLM

---

## Phase d’implémentation

1. **Maintenant** : document + liste des sources prioritaires
2. **Ensuite** : script local de test (fetch 3–5 RSS)
3. **Puis** : GitHub Action
4. **Enfin** : affichage live dans le prototype / site

---

## Légalité

- RSS = usage prévu et autorisé
- Pas de scraping de pages YouTube
- Embeds YouTube uniquement côté frontend
- Respect des robots.txt et conditions d’utilisation

---

*Document de travail — à faire évoluer avec les premiers tests.*
