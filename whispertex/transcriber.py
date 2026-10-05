"""
Speech-to-text transcriber using Whisper.
Supports Groq Whisper (ultra-fast <250ms), OpenAI Whisper, and local endpoints.
"""

import os
import requests
from typing import Dict, Any

def transcribe_audio(audio_path: str, config: Dict[str, Any]) -> str:
    """Transcribes an audio file into plain text using the configured Whisper provider."""
    provider = config.get("stt_provider", "groq")

    if provider == "groq":
        api_key = config.get("groq_api_key") or os.environ.get("GROQ_API_KEY", "")
        if not api_key:
            raise ValueError(
                "Groq API key not found.\n"
                "Get a free key at https://console.groq.com/keys and run:\n"
                "  export GROQ_API_KEY='gsk_...'\n"
                "or configure it with:\n"
                "  whispertex config --groq-key 'gsk_...'"
            )
        url = "https://api.groq.com/openai/v1/audio/transcriptions"
        model = config.get("groq_whisper_model", "whisper-large-v3")
        headers = {"Authorization": f"Bearer {api_key}"}

    elif provider == "openai":
        api_key = config.get("openai_api_key") or os.environ.get("OPENAI_API_KEY", "")
        if not api_key:
            raise ValueError(
                "OpenAI API key not found.\n"
                "Set it via:\n"
                "  export OPENAI_API_KEY='sk_...'\n"
                "or configure it with:\n"
                "  whispertex config --openai-key 'sk_...'"
            )
        url = "https://api.openai.com/v1/audio/transcriptions"
        model = "whisper-1"
        headers = {"Authorization": f"Bearer {api_key}"}

    elif provider == "local":
        url = config.get("custom_whisper_url", "http://localhost:8080/inference")
        model = "whisper"
        headers = {}

    else:
        raise ValueError(f"Unknown STT provider: {provider}")

    with open(audio_path, "rb") as f:
        files = {"file": (os.path.basename(audio_path), f, "audio/wav")}
        data = {"model": model, "language": "en"}
        
        response = requests.post(url, headers=headers, files=files, data=data, timeout=30)

    if response.status_code != 200:
        raise RuntimeError(f"Transcription error ({response.status_code}): {response.text}")

    result = response.json()
    return result.get("text", "").strip()
