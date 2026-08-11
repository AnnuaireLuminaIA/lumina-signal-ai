#!/usr/bin/env python3
"""
Lumina Signal — Ingestion RSS
Usage: python scripts/test-rss.py
"""

import json
import urllib.request
import xml.etree.ElementTree as ET
from datetime import datetime, timezone
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
NS = {
    "atom": "http://www.w3.org/2005/Atom",
    "yt": "http://www.youtube.com/xml/schemas/2015",
    "media": "http://search.yahoo.com/mrss/",
}


def load_sources():
    path = ROOT / "data" / "sources.json"
    with open(path, encoding="utf-8") as f:
        data = json.load(f)
    return [s for s in data["sources"] if s.get("rss")]


def fetch(url: str) -> str:
    req = urllib.request.Request(
        url,
        headers={"User-Agent": "LuminaSignal/0.2 (+https://lumina.signal)"},
    )
    with urllib.request.urlopen(req, timeout=15) as resp:
        return resp.read().decode("utf-8", errors="replace")


def parse_youtube_atom(xml_text: str, voice_id: str, voice_name: str):
    root = ET.fromstring(xml_text)
    items = []
    for entry in root.findall("atom:entry", NS)[:5]:
        title = (entry.findtext("atom:title", default="", namespaces=NS) or "").strip()
        link = ""
        for l in entry.findall("atom:link", NS):
            if l.get("rel") == "alternate":
                link = l.get("href", "")
                break
        published = entry.findtext("atom:published", default="", namespaces=NS) or ""
        video_id = entry.findtext("yt:videoId", default="", namespaces=NS) or ""
        if not link and video_id:
            link = f"https://www.youtube.com/watch?v={video_id}"
        thumb = ""
        thumb_el = entry.find("media:group/media:thumbnail", NS)
        if thumb_el is None:
            thumb_el = entry.find("media:thumbnail", NS)
        if thumb_el is not None:
            thumb = thumb_el.get("url", "")
        if not thumb and video_id:
            thumb = f"https://i.ytimg.com/vi/{video_id}/hqdefault.jpg"
        items.append({
            "voiceId": voice_id,
            "voiceName": voice_name,
            "type": "video",
            "title": title,
            "url": link,
            "publishedAt": published,
            "platform": "youtube",
            "thumbnail": thumb,
        })
    return items


def parse_generic_rss(xml_text: str, voice_id: str, voice_name: str):
    root = ET.fromstring(xml_text)
    items = []
    channel = root.find("channel")
    if channel is not None:
        for item in channel.findall("item")[:5]:
            title = (item.findtext("title") or "").strip()
            link = (item.findtext("link") or "").strip()
            pub = (item.findtext("pubDate") or item.findtext("published") or "").strip()
            items.append({
                "voiceId": voice_id,
                "voiceName": voice_name,
                "type": "podcast",
                "title": title,
                "url": link,
                "publishedAt": pub,
                "platform": "rss",
            })
        return items
    for entry in root.findall("{http://www.w3.org/2005/Atom}entry")[:5]:
        title = (entry.findtext("{http://www.w3.org/2005/Atom}title") or "").strip()
        link_el = entry.find("{http://www.w3.org/2005/Atom}link")
        link = link_el.get("href") if link_el is not None else ""
        pub = (entry.findtext("{http://www.w3.org/2005/Atom}published") or "").strip()
        items.append({
            "voiceId": voice_id,
            "voiceName": voice_name,
            "type": "podcast",
            "title": title,
            "url": link,
            "publishedAt": pub,
            "platform": "rss",
        })
    return items


def main():
    print("Lumina Signal — RSS ingestion\n" + "=" * 50)
    sources = load_sources()
    print(f"Sources actives: {len(sources)}\n")
    all_items = []

    for src in sources:
        print(f"→ {src.get('name', src['voiceId'])} ({src.get('type', '?')})")
        try:
            xml = fetch(src["rss"])
            if src.get("type") == "youtube":
                items = parse_youtube_atom(xml, src["voiceId"], src.get("name", src["voiceId"]))
            else:
                items = parse_generic_rss(xml, src["voiceId"], src.get("name", src["voiceId"]))
            print(f"  {len(items)} éléments")
            for it in items[:2]:
                print(f"  • {it['title'][:70]}")
            all_items.extend(items)
        except Exception as e:
            print(f"  ERREUR: {e}")

    out = ROOT / "data" / "rss-test-output.json"
    with open(out, "w", encoding="utf-8") as f:
        json.dump({
            "fetchedAt": datetime.now(timezone.utc).isoformat(),
            "count": len(all_items),
            "items": all_items,
        }, f, indent=2, ensure_ascii=False)

    print(f"\n→ {out}")
    print(f"  Total: {len(all_items)} contenus")


if __name__ == "__main__":
    main()
