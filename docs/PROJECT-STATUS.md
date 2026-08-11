# Lumina Signal — Project Status

**Date:** 2026-08-11  

## Métriques

| Élément | Valeur |
|---------|--------|
| Voix | 48 |
| Sources RSS | 14 |
| Contenus live | 70 |
| FR | 10 |
| Briefing | JSON + UI wired |

## Pipeline

```bash
bash scripts/refresh.sh
```

1. RSS fetch  
2. Normalize → live-contents.json  
3. Briefing → briefing-latest.json  

Le prototype v4 embarque le briefing et l’utilise en priorité.

## Status

**Produit end-to-end opérationnel.**
