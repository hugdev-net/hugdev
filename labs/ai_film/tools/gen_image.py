#!/usr/bin/env python3
import argparse
import base64
import requests
import json
import time


GEMINI_2_5_FLASH_API_URL = "https://api.gptsapi.net/api/v3/google/gemini-2.5-flash-image-hd/text-to-image"
GEMINI_3_PRO_API_URL = "https://api.gptsapi.net/api/v3/google/gemini-3-pro-image-preview/text-to-image"


def wait_for_result(result_url, headers, timeout=180, interval=20, debug=False):
    """
    Poll prediction result until status == completed
    """
    start = time.time()

    while True:
        if time.time() - start > timeout:
            raise TimeoutError(f"Image generation timed out. url={result_url}")

        resp = requests.get(result_url, headers=headers)
        resp.raise_for_status()
        result = resp.json()

        if debug:
            print(f"[DEBUG] url={result_url} result={json.dumps(result, indent=2, ensure_ascii=False)}")

        data = result.get("data", {})
        status = data.get("status")

        print(f"[INFO] status = {status}")

        if status == "completed":
            return data

        if status in ("failed", "error", "canceled"):
            raise RuntimeError(f"Generation failed: {result}")

        time.sleep(interval)


def download_image(url, out_path):
    """
    Download image from URL
    """
    print(f"[INFO] Downloading image from {url} to {out_path}")
    resp = requests.get(url, timeout=120)
    resp.raise_for_status()

    with open(out_path, "wb") as f:
        f.write(resp.content)


def main():
    parser = argparse.ArgumentParser(
        description="Text-to-Image CLI (gptsapi / Gemini Flash Image HD)"
    )

    parser.add_argument("--api-key", required=True, help="API Key")
    parser.add_argument("--prompt", required=True, help="Image prompt")
    parser.add_argument("--model", default="pro", help="pro or hd")
    parser.add_argument("--aspect-ratio", default="16:9", help="Aspect ratio, e.g. 1:1, 16:9")
    parser.add_argument("--out", default="output", help="Output file name (without extension)")
    parser.add_argument("--timeout", type=int, default=240, help="Max wait time (seconds)")
    parser.add_argument("--interval", type=int, default=16, help="Polling interval (seconds)")
    parser.add_argument("--debug", type=bool, default=True, help="Print raw JSON responses")

    args = parser.parse_args()

    headers = {
        "Authorization": f"Bearer {args.api_key}",
        "Content-Type": "application/json",
    }

    payload = {
        "prompt": args.prompt,
        "aspect_ratio": args.aspect_ratio,
        "output_format": "jpg",
    }

    # 1. Create prediction
    print("[INFO] Creating image generation task...")
    api_url = GEMINI_3_PRO_API_URL if args.model == "pro" else GEMINI_2_5_FLASH_API_URL
    resp = requests.post(api_url, headers=headers, json=payload)
    resp.raise_for_status()
    resp_json = resp.json()

    if args.debug:
        print("[DEBUG] create response:", json.dumps(resp_json, indent=2, ensure_ascii=False))

    result_url = resp_json["data"]["urls"]["get"]

    # 2. Wait for completion
    print("[INFO] Waiting for generation result...")
    result_data = wait_for_result(
        result_url,
        headers,
        timeout=args.timeout,
        interval=args.interval,
        debug=args.debug,
    )

    outputs = result_data.get("outputs", [])
    if not outputs:
        raise RuntimeError("No outputs returned")

    # 3. Download images
    for idx, image_url in enumerate(outputs):
        ext = "jpg"
        if len(outputs) == 1:
            out_file = f"{args.out}{ext}"
        else:
            out_file = f"{args.out}_{idx}{ext}"

        print(f"[INFO] Downloading image {idx + 1}: {image_url}")
        download_image(image_url, out_file)
        print(f"[OK] Saved: {out_file}")

    print("[DONE] All images downloaded successfully")


if __name__ == "__main__":
    main()
