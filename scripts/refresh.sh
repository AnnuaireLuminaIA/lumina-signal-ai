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
import hashlib
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



def is_ai_relevant(title, voice_id):
    """For generalist sources, keep only AI-related titles."""
    GENERALISTS = {"thinkerview"}
    if voice_id not in GENERALISTS:
        return True
    t = (title or "").lower()
    keywords = [
        "i.a", "ia ", " ia", "ia:", "ia,", "ia.", "l'ia", "l’ia",
        "intelligence artificielle", "artificial intelligence",
        "machine learning", "deep learning", "llm", "gpt", "chatgpt",
        "claude", "openai", "mistral", "gemini", "neural", "neurone",
        "algorithme", "algorithm", "robot", "automation", "automatisation",
        "data science", "big data", "octets", "numérique et", "digital",
        "silicon", "transhuman", "singularity", "agi", "alignement",
        "babinet",  # often AI guests on Thinkerview
        "ia ", "ai ", " a.i", "a.i.",
    ]
    # accent-insensitive light check
    return any(k in t for k in keywords)

def topics_from_title(title):
    t = (title or "").lower()
    topics = []
    rules = [
        ("agents", ["agent", "agents", "tool use", "tool-use", "multiagent", "multi-agent"]),
        ("safety", ["safety", "alignment", "x-risk", "catastrophic", "rlhf"]),
        ("open-source", ["open source", "open-source", "open weight", "open-weight", "llama", "mistral", "huggingface"]),
        ("reasoning", ["reason", "o1", "chain-of-thought", "cot", "test-time"]),
        ("multimodal", ["vision", "image", "video", "multimodal", "audio"]),
        ("infra", ["gpu", "cuda", "kernel", "inference", "serving", "vllm"]),
        ("policy", ["policy", "regulation", "governance", "law"]),
        ("education", ["course", "tutorial", "from scratch", "intro"]),
    ]
    for name, kws in rules:
        if any(k in t for k in kws):
            topics.append(name)
    return topics[:4]

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
    if not is_ai_relevant(item.get("title", ""), item.get("voiceId", "")):
        continue
    voice = voices.get(item["voiceId"], {})
    dt = parse_date(item.get("publishedAt", ""))
    lang = "fr" if item["voiceId"] in ("nicolas-guyon", "ludovic-salenne", "thinkerview") else "en"
    normalized.append({
        "id": item.get("voiceId", "x") + "-" + hashlib.sha1((item.get("url") or item.get("title") or "").encode()).hexdigest()[:12],
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
        "topics": topics_from_title(item.get("title", "")),
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
import hashlib
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
# Lightweight editorial line from top topics
from collections import Counter
topic_counter = Counter()
for c in contents:
    for t in c.get("topics") or []:
        topic_counter[t] += 1
top_topics = [t for t,_ in topic_counter.most_common(3)]
fr_n = sum(1 for c in contents if c.get("language")=="fr")
if top_topics:
    editorial = f"Dominant aujourd'hui : {', '.join(top_topics)}. {fr_n} contenus FR dans le flux."
else:
    editorial = f"{len(contents)} contenus agrégés · {fr_n} en français · curation high-signal."

briefing = {
    "date": datetime.now(timezone.utc).strftime("%Y-%m-%d"),
    "generatedAt": datetime.now(timezone.utc).isoformat(),
    "title": "Briefing du jour",
    "summary": f"{len(contents)} contenus · top {len(top)} signaux",
    "editorial": editorial,
    "editorialEn": f"Today's dominant topics: {', '.join(top_topics) if top_topics else 'mixed'}. {fr_n} FR items in the feed.",
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

