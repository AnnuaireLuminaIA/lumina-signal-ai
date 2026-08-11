# Lumina Signal

**High-signal AI voices, live.**

## Site public

https://annuaireluminaia.github.io/lumina-signal-ai/

Prototype direct :  
https://annuaireluminaia.github.io/lumina-signal-ai/prototypes/lumina-signal-v4.html

## Features

- 48 voix curées (Signal Score)
- 14 sources RSS
- Feed live + Briefing du jour
- Filtres catégorie / pays
- FR + EN
- Auto-refresh toutes les 6 h (GitHub Actions)

## Architecture

```
scripts/refresh.sh     → fetch RSS → data/live-contents.json + briefing-latest.json
prototypes/v4.html     → charge les JSON en live (fetch)
.github/workflows/     → cron 6h
```

## Refresh local

```bash
bash scripts/refresh.sh
```

## Repo

https://github.com/AnnuaireLuminaIA/lumina-signal-ai
