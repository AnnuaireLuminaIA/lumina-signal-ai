#!/usr/bin/env python3
"""Translate content titles with Gemini. Uses GEMINI_API_KEY env var.
Stores titleFr / titleEn on each content item. Skips if no key."""
from __future__ import annotations

import json
import os
import time
import urllib.error
import urllib.request
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
LIVE = ROOT / "data" / "live-contents.json"
MODEL = os.environ.get("GEMINI_MODEL", "gemini-2.0-flash")
API_BASE = "https://generativelanguage.googleapis.com/v1beta/models"


def detect_lang(title: str, declared: str | None) -> str:
    if declared in ("fr", "en"):
        return declared
    if any(c in (title or "") for c in "àâäéèêëïîôùûüçÀÂÄÉÈÊËÏÎÔÙÛÜÇ"):
        return "fr"
    return "en"


def gemini_translate(key: str, text: str, target: str) -> str | None:
    prompt = (
        f"Translate this video or podcast title to {target}. "
        "Return ONLY the translation, no quotes, no explanation:\n"
        f"{text}"
    )
    url = f"{API_BASE}/{MODEL}:generateContent?key={key}"
    body = json.dumps(
        {
            "contents": [{"parts": [{"text": prompt}]}],
            "generationConfig": {"temperature": 0.2, "maxOutputTokens": 100},
        }
    ).encode("utf-8")
    req = urllib.request.Request(
        url,
        data=body,
        headers={"Content-Type": "application/json"},
        method="POST",
    )
    try:
        with urllib.request.urlopen(req, timeout=30) as resp:
            data = json.loads(resp.read().decode("utf-8"))
        text_out = (
            data.get("candidates", [{}])[0]
            .get("content", {})
            .get("parts", [{}])[0]
            .get("text", "")
            .strip()
        )
        if not text_out:
            return None
        return text_out.strip().strip('"«»')
    except urllib.error.HTTPError as e:
        err = e.read().decode("utf-8", errors="replace")[:300]
        print(f"  ! HTTP {e.code}: {err}")
        return None
    except Exception as e:
        print(f"  ! {e}")
        return None


def main() -> None:
    key = os.environ.get("GEMINI_API_KEY", "").strip()
    if not key:
        print("→ Translate titles: skipped (no GEMINI_API_KEY)")
        return

    if not LIVE.exists():
        print("→ Translate titles: no live-contents.json")
        return

    live = json.loads(LIVE.read_text(encoding="utf-8"))
    contents = live.get("contents") or []
    changed = 0
    calls = 0
    max_calls = int(os.environ.get("GEMINI_MAX_CALLS", "40"))

    print(f"→ Translate titles (model={MODEL}, max={max_calls})…")

    for c in contents:
        if calls >= max_calls:
            print(f"  · reached max calls ({max_calls}), rest on next run")
            break
        title = (c.get("title") or "").strip()
        if not title:
            continue
        src = detect_lang(title, c.get("language"))
        c["language"] = src

        # Ensure original language field is filled
        if src == "fr" and not c.get("titleFr"):
            c["titleFr"] = title
            changed += 1
        if src == "en" and not c.get("titleEn"):
            c["titleEn"] = title
            changed += 1

        need_fr = src != "fr" and not c.get("titleFr")
        need_en = src != "en" and not c.get("titleEn")

        if need_fr:
            tr = gemini_translate(key, title, "French")
            calls += 1
            if tr:
                c["titleFr"] = tr
                changed += 1
                print(f"  FR ← {title[:50]}…")
            time.sleep(0.35)

        if need_en and calls < max_calls:
            tr = gemini_translate(key, title, "English")
            calls += 1
            if tr:
                c["titleEn"] = tr
                changed += 1
                print(f"  EN ← {title[:50]}…")
            time.sleep(0.35)

    live["contents"] = contents
    LIVE.write_text(json.dumps(live, indent=2, ensure_ascii=False), encoding="utf-8")
    print(f"  done: {changed} fields updated, {calls} API calls")


if __name__ == "__main__":
    main()
