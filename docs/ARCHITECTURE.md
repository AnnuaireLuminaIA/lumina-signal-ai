# Lumina Signal — Architecture V1

## Objectif

Créer un outil premium, léger et maintenable pour suivre les voix IA les plus sérieuses, avec un assistant intelligent et un système de mise à jour semi-automatique.

---

## Principes techniques

- **Simplicité d’abord** : JSON + HTML/JS au début, puis migration progressive
- **Curation humaine** comme cœur de valeur
- **Assistant IA** comme amplificateur, pas comme remplacement
- **Légalité** : RSS + embeds YouTube uniquement (pas de scraping agressif)
- **Bilingue** dès le départ (FR / EN)

---

## Stack recommandée (V1)

| Couche | Choix | Raison |
|--------|------|--------|
| Frontend | Next.js (App Router) | SEO, performance, React moderne |
| Styling | Tailwind + design tokens | Rapidité + cohérence |
| Données | JSON → Supabase | Simple au début, scalable après |
| Auth | Optionnelle (Phase 2) | Watchlist locale d’abord |
| Assistant | LLM + retrieval simple | Sur métadonnées des voix + titres/résumés |
| Ingestion | GitHub Actions + RSS | Robot de mise à jour |
| Hosting | Vercel | Déploiement simple |

---

## Flux de données

```
Sources (YouTube RSS + Podcast RSS)
        ↓
Robot (GitHub Action / script)
        ↓
Contenus normalisés (JSON ou DB)
        ↓
Frontend (Feed + Fiches + Assistant)
```

---

## Modules prioritaires

1. **Voices Dataset** (fait — en cours d’enrichissement)
2. **Feed unifié** (vidéos + épisodes podcast)
3. **Fiches voix** avec tous les liens
4. **Filtres** (catégorie, pays, langue, type)
5. **Watchlist** (localStorage → compte plus tard)
6. **Assistant** (recommandations + résumés)
7. **Briefing du jour**

---

## Roadmap technique

### Phase 1 — Fondation (actuelle)
- Dataset voix propre
- Prototype design
- Structure projet

### Phase 2 — Prototype vivant
- Chargement des données JSON
- Filtres fonctionnels
- Fiches dynamiques

### Phase 3 — Contenu vivant
- Ingestion RSS
- Feed temps réel / quasi temps réel
- Assistant basique

### Phase 4 — Produit
- Comptes utilisateurs
- Personnalisation
- Intégration Lumina IA

---

## Règles de curation (rappels)

- Maximum ~48 voix
- Score élevé exigé sur profondeur + faible hype
- Priorité aux contenus publics facilement suivables
- Mise à jour manuelle de la liste (qualité > automatisation)

---

*Document vivant — mis à jour au fil de l’avancement*
