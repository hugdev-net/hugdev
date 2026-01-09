import os
import uuid
import subprocess
from fastapi import FastAPI, UploadFile, File
from server.engine import OpenVoiceEngine
from server.speaker_store import save_speaker, load_speaker
from server.schemas import SpeakerRegisterResp, TTSRequest

app = FastAPI(title="OpenVoice V1 TTS Service")

engine = OpenVoiceEngine()

os.makedirs("outputs", exist_ok=True)

def mp3_to_wav(src: str) -> str:
    dst = f"/tmp/{uuid.uuid4()}.wav"
    subprocess.run([
        "ffmpeg", "-y",
        "-i", src,
        "-ac", "1",
        "-ar", "16000",
        dst
    ], check=True)
    return dst


@app.post("/speaker/register", response_model=SpeakerRegisterResp)
async def register_speaker(file: UploadFile = File(...)):
    mp3_path = f"/tmp/{uuid.uuid4()}.mp3"
    with open(mp3_path, "wb") as f:
        f.write(await file.read())

    wav_path = mp3_to_wav(mp3_path)
    se = engine.extract_speaker(wav_path)
    speaker_id = save_speaker(se)

    return SpeakerRegisterResp(speaker_id=speaker_id)


@app.post("/tts")
async def tts(req: TTSRequest):
    speaker_se = load_speaker(req.speaker_id)

    out_path = f"outputs/{uuid.uuid4()}.wav"
    engine.tts(req.text, speaker_se, out_path)

    return {
        "status": "ok",
        "wav_path": out_path
    }


@app.get("/health")
def health():
    return {"status": "ok"}

