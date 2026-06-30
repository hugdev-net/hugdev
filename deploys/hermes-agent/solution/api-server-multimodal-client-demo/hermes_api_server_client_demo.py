#!/usr/bin/env python3
"""
Minimal client demo for Hermes API Server multimodal calls.

It calls POST /v1/responses with:
- text-only input
- text + image URL input
- text + local image input, converted to data:image/...;base64,...

No third-party dependency is required. This is intentionally a demo script,
not a reusable SDK.
"""

from __future__ import annotations

import argparse
import base64
import json
import mimetypes
import os
import re
import shutil
import sys
import time
from pathlib import Path
from typing import Any
from urllib import error, request
from urllib.parse import urlparse


DEFAULT_API_BASE = "http://127.0.0.1:8642"
DEFAULT_MODEL = "hermes-agent"

MARKDOWN_IMAGE_RE = re.compile(r"!\[[^\]]*\]\((?P<url>[^)\s]+)\)")
RAW_IMAGE_URL_RE = re.compile(
    r"(?P<url>https?://[^\s)>'\"]+\.(?:png|jpe?g|webp|gif)(?:\?[^\s)>'\"]*)?)",
    re.IGNORECASE,
)
MEDIA_RE = re.compile(r"MEDIA:\s*`?(?P<ref>[^\s`'\"<>]+)`?", re.IGNORECASE)


def image_file_to_data_url(path: Path) -> str:
    mime = mimetypes.guess_type(str(path))[0] or "application/octet-stream"
    if not mime.startswith("image/"):
        raise ValueError(f"{path} is not detected as an image file, mime={mime!r}")
    data = base64.b64encode(path.read_bytes()).decode("ascii")
    return f"data:{mime};base64,{data}"


def build_content(text: str, image_url: str | None, image_path: Path | None) -> list[dict[str, Any]]:
    content: list[dict[str, Any]] = [{"type": "input_text", "text": text}]
    if image_url:
        content.append({"type": "input_image", "image_url": image_url})
    if image_path:
        content.append({"type": "input_image", "image_url": image_file_to_data_url(image_path)})
    return content


def post_json(url: str, body: dict[str, Any], headers: dict[str, str]) -> dict[str, Any]:
    data = json.dumps(body, ensure_ascii=False).encode("utf-8")
    req = request.Request(url, data=data, headers=headers, method="POST")
    try:
        with request.urlopen(req, timeout=300) as resp:
            payload = resp.read().decode("utf-8")
    except error.HTTPError as exc:
        err_body = exc.read().decode("utf-8", errors="replace")
        raise RuntimeError(f"HTTP {exc.code}: {err_body}") from exc
    except error.URLError as exc:
        raise RuntimeError(f"Request failed: {exc}") from exc
    return json.loads(payload)


def extract_output_text(response_body: dict[str, Any]) -> str:
    texts: list[str] = []
    for item in response_body.get("output", []):
        if not isinstance(item, dict):
            continue
        if item.get("type") != "message":
            continue
        for part in item.get("content", []):
            if not isinstance(part, dict):
                continue
            if part.get("type") in {"output_text", "text"}:
                texts.append(str(part.get("text") or ""))
    return "\n".join(t for t in texts if t)


def extract_media_refs(text: str) -> list[str]:
    refs: list[str] = []
    for regex, group_name in (
        (MARKDOWN_IMAGE_RE, "url"),
        (RAW_IMAGE_URL_RE, "url"),
        (MEDIA_RE, "ref"),
    ):
        for match in regex.finditer(text):
            value = match.group(group_name).strip()
            if value and value not in refs:
                refs.append(value)
    return refs


def download_or_copy_media(refs: list[str], out_dir: Path) -> None:
    out_dir.mkdir(parents=True, exist_ok=True)
    for idx, ref in enumerate(refs, start=1):
        parsed = urlparse(ref)
        if parsed.scheme in {"http", "https"}:
            suffix = Path(parsed.path).suffix or ".bin"
            target = out_dir / f"media_{idx}{suffix}"
            try:
                request.urlretrieve(ref, target)
                print(f"downloaded: {ref} -> {target}")
            except Exception as exc:
                print(f"download failed: {ref} ({exc})")
        elif parsed.scheme == "data" and ref.startswith("data:image/"):
            header, _, b64_data = ref.partition(",")
            ext = "." + header.split("data:image/", 1)[1].split(";", 1)[0].replace("jpeg", "jpg")
            target = out_dir / f"media_{idx}{ext}"
            target.write_bytes(base64.b64decode(b64_data))
            print(f"saved data URL: {target}")
        else:
            path = Path(ref)
            if path.exists():
                target = out_dir / path.name
                shutil.copy2(path, target)
                print(f"copied local media: {path} -> {target}")
            else:
                print(f"media ref is not directly downloadable by this client: {ref}")


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Hermes API Server multimodal Responses API demo")
    parser.add_argument("--api-base", default=os.getenv("HERMES_API_BASE", DEFAULT_API_BASE))
    parser.add_argument("--api-key", default=os.getenv("HERMES_API_KEY", ""))
    parser.add_argument("--model", default=os.getenv("HERMES_MODEL", DEFAULT_MODEL))
    parser.add_argument("--text", required=True, help="User text to send")
    parser.add_argument("--image-url", help="HTTP(S) image URL or data:image/... URL")
    parser.add_argument("--image", type=Path, help="Local image file to inline as data:image/... URL")
    parser.add_argument("--previous-response-id", help="Continue server-side Responses API context")
    parser.add_argument("--conversation", help="Optional server-side conversation name")
    parser.add_argument("--session-key", help="Stable customer/channel id for long-term memory scope")
    parser.add_argument("--download-media", action="store_true", help="Download/copy media refs found in the answer")
    parser.add_argument("--media-dir", type=Path, default=Path("downloads"))
    return parser.parse_args()


def main() -> int:
    args = parse_args()
    if args.previous_response_id and args.conversation:
        print("Use either --previous-response-id or --conversation, not both.", file=sys.stderr)
        return 2
    if args.image and not args.image.exists():
        print(f"Image file not found: {args.image}", file=sys.stderr)
        return 2

    url = args.api_base.rstrip("/") + "/v1/responses"
    headers = {"Content-Type": "application/json"}
    if args.api_key:
        headers["Authorization"] = f"Bearer {args.api_key}"
    if args.session_key:
        headers["X-Hermes-Session-Key"] = args.session_key

    body: dict[str, Any] = {
        "model": args.model,
        "input": [
            {
                "role": "user",
                "content": build_content(args.text, args.image_url, args.image),
            }
        ],
        "store": True,
    }
    if args.previous_response_id:
        body["previous_response_id"] = args.previous_response_id
    if args.conversation:
        body["conversation"] = args.conversation

    print(f"POST {url}")
    started = time.time()
    try:
        response_body = post_json(url, body, headers)
    except Exception as exc:
        print(str(exc), file=sys.stderr)
        return 1

    elapsed = time.time() - started
    output_text = extract_output_text(response_body)
    media_refs = extract_media_refs(output_text)

    print(f"\nresponse_id: {response_body.get('id')}")
    print(f"elapsed_sec: {elapsed:.1f}")
    print("\nassistant_text:")
    print(output_text or "(empty)")

    if media_refs:
        print("\nmedia_refs_found_in_text:")
        for ref in media_refs:
            print(f"- {ref}")
        if args.download_media:
            print()
            download_or_copy_media(media_refs, args.media_dir)
    else:
        print("\nmedia_refs_found_in_text: none")

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
