import os
import uuid
import torch

SPEAKER_DIR = "speakers"
os.makedirs(SPEAKER_DIR, exist_ok=True)


def save_speaker(se) -> str:
    speaker_id = f"spk_{uuid.uuid4().hex[:8]}"
    path = os.path.join(SPEAKER_DIR, f"{speaker_id}.pt")
    torch.save(se, path)
    return speaker_id


def load_speaker(speaker_id: str):
    path = os.path.join(SPEAKER_DIR, f"{speaker_id}.pt")
    if not os.path.exists(path):
        raise FileNotFoundError(f"speaker_id not found: {speaker_id}")
    return torch.load(path, map_location="cuda")

