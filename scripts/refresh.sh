#!/bin/bash
# Refresh live contents from RSS sources
set -e
cd "$(dirname "$0")/.."
echo "→ Fetching RSS..."
python3 scripts/test-rss.py
echo ""
echo "→ Normalizing..."
python3 - << 'PY'
import json
from datetime import datetime, timezone
from pathlib import Path

ROOT = Path(".")
with open(ROOT / "data/rss-test-output.json") as f:
    raw = json.load(f)
with open(ROOT / "data/lumina-signal-voices.json") as f:
    voices = {v["id"]: v for v in json.load(f)["voices"]}

def parse_date(s):
    if not s: return None
    s2 = s.strip().replace("Z", "+00:00")
    for fmt in ["%Y-%m-%dT%H:%M:%S%z", "%Y-%m-%dT%H:%M:%S.%f%z", "%a, %d %b %Y %H:%M:%S %z"]:
        try: return datetime.strptime(s2 if "%z" in fmt else s.strip(), fmt)
        except: continue
    try: return datetime.fromisoformat(s2)
    except: return None

def relative_ago(dt):
    if not dt: return ""
    if dt.tzinfo is None: dt = dt.replace(tzinfo=timezone.utc)
    delta = datetime.now(timezone.utc) - dt
    d, s = delta.days, delta.seconds
    if d < 0: return "À venir"
    if d == 0: return f"Il y a {s // 60} min" if s < 3600 else f"Il y a {s // 3600}h"
    if d == 1: return "Il y a 1j"
    if d < 7: return f"Il y a {d}j"
    if d < 30: return f"Il y a {d // 7} sem."
    return f"Il y a {d // 30} mois"

normalized = []
for item in raw["items"]:
    voice = voices.get(item["voiceId"], {})
    dt = parse_date(item.get("publishedAt", ""))
    lang = "fr" if item["voiceId"] in ("nicolas-guyon", "ludovic-salenne", "thinkerview") else "en"
    normalized.append({
        "id": f"{item['voiceId']}-{abs(hash(item.get('url', item['title']))) % 10**8}",
        "voiceId": item["voiceId"],
        "type": item.get("type", "video"),
        "title": item["title"],
        "description": "",
        "url": item.get("url", ""),
        "thumbnail": item.get("thumbnail", ""),
        "duration": "—",
        "ago": relative_ago(dt),
        "publishedAt": item.get("publishedAt", ""),
        "platform": item.get("platform", "youtube"),
        "signalScore": voice.get("signalScore", 8.0),
        "topics": [],
        "language": lang,
        "isNew": True
    })
normalized.sort(key=lambda x: (parse_date(x.get("publishedAt") or "") or datetime.min.replace(tzinfo=timezone.utc)).timestamp(), reverse=True)
out = {"meta": {"updated": datetime.now(timezone.utc).isoformat(), "count": len(normalized)}, "generatedAt": datetime.now(timezone.utc).isoformat(),
        "contents": normalized}
with open(ROOT / "data/live-contents.json", "w") as f:
    json.dump(out, f, indent=2, ensure_ascii=False)
print(f"  {len(normalized)} contents → data/live-contents.json")
PY

echo ""
echo "→ Translating titles (Gemini if key present)..."
python3 scripts/translate_titles.py || echo "  (translate step skipped/failed)"

echo ""
echo "→ Generating briefing..."
python3 - << 'PY2'
import json
from datetime import datetime, timezone
from pathlib import Path
ROOT = Path(".")
with open(ROOT / "data/live-contents.json") as f:
    live = json.load(f)
with open(ROOT / "data/lumina-signal-voices.json") as f:
    voices = {v["id"]: v for v in json.load(f)["voices"]}
contents = live["contents"]
seen, top = set(), []
for c in sorted(contents, key=lambda x: -x.get("signalScore", 0)):
    if c["voiceId"] in seen: continue
    seen.add(c["voiceId"])
    v = voices.get(c["voiceId"], {})
    top.append({
        "rank": len(top)+1, "title": c["title"], "voiceId": c["voiceId"],
        "voiceName": v.get("name", c["voiceId"]), "signalScore": c.get("signalScore"),
        "ago": c.get("ago"), "url": c.get("url"), "language": c.get("language", "en"),
        "why": v.get("why", "Signal élevé.")
    })
    if len(top) >= 7: break
briefing = {
    "date": datetime.now(timezone.utc).strftime("%Y-%m-%d"),
    "generatedAt": datetime.now(timezone.utc).isoformat(),
    "title": "Briefing du jour",
    "summary": f"{len(contents)} contenus · top {len(top)} signaux",
    "items": top,
    "stats": {
        "totalContents": len(contents),
        "sources": len({c["voiceId"] for c in contents}),
        "frCount": sum(1 for c in contents if c.get("language")=="fr"),
        "enCount": sum(1 for c in contents if c.get("language")!="fr"),
    }
}
with open(ROOT / "data/briefing-latest.json", "w") as f:
    json.dump(briefing, f, indent=2, ensure_ascii=False)
print(f"  {len(top)} signaux → data/briefing-latest.json")
PY2
echo "✓ Full refresh done."

