from pydantic import BaseModel


class SpeakerRegisterResp(BaseModel):
    speaker_id: str


class TTSRequest(BaseModel):
    text: str
    speaker_id: str

