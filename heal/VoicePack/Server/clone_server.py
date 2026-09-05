#!/usr/bin/env python3
"""
Voice-clone server for the MaraVoice Swift helper.

Run on your Mac (Apple Silicon uses the GPU via MPS automatically):
    pip install f5-tts fastapi uvicorn
    python3 clone_server.py            # listens on http://0.0.0.0:8000

Endpoints:
    POST /speak   {"text": "..."}   -> audio/wav of the cloned voice
    GET  /health                    -> {"ok": true}
"""
import io
import os
import sys

import numpy as np
import soundfile as sf
from fastapi import FastAPI
from fastapi.responses import Response
from pydantic import BaseModel

HERE = os.path.dirname(os.path.abspath(__file__))
VOICE_PACK = os.path.abspath(os.path.join(HERE, ".."))
REF_WAV = os.path.join(VOICE_PACK, "reference.wav")
REF_TXT = open(os.path.join(VOICE_PACK, "reference.txt")).read().strip()

print("Loading F5-TTS model...", file=sys.stderr)
from f5_tts.api import F5TTS  # noqa: E402
tts = F5TTS(model="F5TTS_v1_Base")
print("Model ready.", file=sys.stderr)

app = FastAPI(title="MaraVoice clone server")


class SpeakRequest(BaseModel):
    text: str
    speed: float = 1.0


@app.get("/health")
def health():
    return {"ok": True}


@app.post("/speak")
def speak(req: SpeakRequest):
    wav, sr, _ = tts.infer(
        ref_file=REF_WAV,
        ref_text=REF_TXT,
        gen_text=req.text,
        nfe_step=32,
        speed=req.speed,
        show_info=lambda *_: None,
    )
    buf = io.BytesIO()
    sf.write(buf, np.asarray(wav, dtype=np.float32), sr, format="WAV", subtype="PCM_16")
    return Response(content=buf.getvalue(), media_type="audio/wav")


if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)
