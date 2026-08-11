# Traduction des titres (Gemini)

## Pour tous les visiteurs (recommandé)

1. Crée une clé gratuite : https://aistudio.google.com/apikey
2. Sur le repo GitHub → **Settings** → **Secrets and variables** → **Actions**
3. **New repository secret**
   - Name : `GEMINI_API_KEY`
   - Value : ta clé `AIza...`
4. **Actions** → **Refresh Lumina Signal** → **Run workflow**

Le robot traduit jusqu’à 40 titres par run et enregistre `titleFr` / `titleEn` dans `data/live-contents.json`.

## Fallback navigateur

Le bouton **🌐 Traduire** + **⚙** reste disponible pour un usage personnel (clé en localStorage).
