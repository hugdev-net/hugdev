
import os
import torch
from openvoice.api import BaseSpeakerTTS, ToneColorConverter
from openvoice import se_extractor

DEVICE = "cuda" if torch.cuda.is_available() else "cpu"

BASE_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
CKPT_DIR = os.path.join(BASE_DIR, "checkpoints")


class OpenVoiceEngine:
    def __init__(self):
        # 1️⃣ Base speaker TTS（中文）
        self.base_tts = BaseSpeakerTTS(
            config_path=os.path.join(
                CKPT_DIR,
                "base_speakers",
                "ZH",
                "config.json"
            ),
            device=DEVICE
        )
        self.base_tts.load_ckpt(
            os.path.join(
                CKPT_DIR,
                "base_speakers",
                "ZH",
                "checkpoint.pth"
            )
        )

        # 2️⃣ Tone color converter（V1 正确用法）
        self.converter = ToneColorConverter(
            config_path=os.path.join(
                CKPT_DIR,
                "converter",
                "config.json"
            ),
            device=DEVICE
        )
        self.converter.load_ckpt(
            os.path.join(
                CKPT_DIR,
                "converter",
                "checkpoint.pth"
            )
        )

        # ❌ 不要再 load speaker_encoder
        # V1 的 se_extractor 会自行处理

    def extract_speaker(self, wav_path: str):
        # ✅ V1 正确方式：直接传 converter
        se, _ = se_extractor.get_se(
            wav_path,
            self.converter,
            vad=True
        )
        return se

    def tts(self, text: str, speaker_se, out_path: str):
        tmp_path = "/tmp/base.wav"

        self.base_tts.tts(
            text=text,
            output_path=tmp_path
        )

        self.converter.convert(
            audio_src_path=tmp_path,
            src_se=None,
            tgt_se=speaker_se,
            output_path=out_path
        )

