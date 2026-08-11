# Lumina Signal — Briefing du jour

## Objectif

Le bénéfice central du produit :

> En 30–60 secondes, savoir **ce qui compte vraiment** dans l’IA sérieuse aujourd’hui.

Pas une simple liste de vidéos.  
Un **filtre intelligent + contexte**.

---

## Structure du Briefing

### 1. Header
- Date
- Nombre de contenus analysés
- Période (dernières 24–72h)

### 2. Top Signaux (3 à 7 items max)

Pour chaque item :
- Titre
- Voix + score
- **Pourquoi c’est important** (1–2 phrases)
- Type (vidéo / podcast)
- Lien

### 3. Thèmes du moment (optionnel)
- 2–4 tags dominants (ex: agents, open-weight, evals, safety)

### 4. À surveiller
- 1–2 contenus plus anciens mais encore très pertinents

---

## Logique de sélection (V1)

1. Prendre les contenus des 72 dernières heures
2. Trier par `signalScore` de la voix + récence
3. Diversifier les voix (éviter 4 items de la même personne)
4. Limiter à 5–7 items max

Plus tard :
- Scoring contenu (pas seulement voix)
- Résumé automatique
- Personnalisation selon watchlist

---

## Exemple de rendu (texte)

**Briefing — 11 août 2026**

**Top signaux**

1. **Muse Glimmer and Spark** — Latent Space (9.0)  
   Open weights + personal superintelligence. Signal fort sur le retour des modèles ouverts utilisables.

2. **How a Random Lunch Led Physics into the Riemann Hypothesis** — Dwarkesh / Grant Sanderson (9.4)  
   Croisement rare math profonde + IA. Karpathy/Dwarkesh territory.

3. **AlphaZero for Mathematics** — Dwarkesh (9.4)  
   Suite logique : l’IA qui attaque les maths fondamentales.

...

---

## Implémentation

### Court terme (prototype)
- Bouton “Briefing du jour” déjà présent
- Générer un panneau / modal avec les top items + une phrase “pourquoi”

### Moyen terme
- Génération quotidienne via le robot
- Stockage d’un `briefing-YYYY-MM-DD.json`
- Affichage prioritaire sur le Feed

---

*Le Briefing est le cœur de la promesse produit.*
