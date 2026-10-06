"""
Configuration management for WhisperTeX.
Handles loading/saving settings from ~/.whispertex/config.json and environment variables.
"""

import os
import json
from pathlib import Path
from typing import Dict, Any

CONFIG_DIR = Path.home() / ".whispertex"
CONFIG_FILE = CONFIG_DIR / "config.json"

DEFAULT_CONFIG: Dict[str, Any] = {
    "provider": "groq",  # groq | openai | gemini | ollama | offline
    "stt_provider": "groq",  # groq | openai | local
    "delimiter": "display",  # display ($$) | inline ($) | bracket (\[\]) | raw
    "auto_paste": True,  # automatically paste via Cmd+V into focused app
    "hotkey": "<cmd>+<shift>+l",
    "groq_api_key": "",
    "groq_model": "llama-3.1-8b-instant",
    "groq_whisper_model": "whisper-large-v3",
    "openai_api_key": "",
    "openai_model": "gpt-4o-mini",
    "gemini_api_key": "",
    "gemini_model": "gemini-2.0-flash",
    "ollama_endpoint": "http://localhost:11434/api/generate",
    "ollama_model": "llama3",
}

def get_config_dir() -> Path:
    CONFIG_DIR.mkdir(parents=True, exist_ok=True)
    return CONFIG_DIR

def load_config() -> Dict[str, Any]:
    """Loads configuration with env var overrides taking precedence."""
    config = DEFAULT_CONFIG.copy()
    
    if CONFIG_FILE.exists():
        try:
            with open(CONFIG_FILE, "r", encoding="utf-8") as f:
                saved = json.load(f)
                config.update(saved)
        except Exception:
            pass

    # Environment variable overrides
    if os.environ.get("GROQ_API_KEY"):
        config["groq_api_key"] = os.environ["GROQ_API_KEY"]
    if os.environ.get("OPENAI_API_KEY"):
        config["openai_api_key"] = os.environ["OPENAI_API_KEY"]
    if os.environ.get("GEMINI_API_KEY"):
        config["gemini_api_key"] = os.environ["GEMINI_API_KEY"]
    if os.environ.get("WHISPERTEX_PROVIDER"):
        config["provider"] = os.environ["WHISPERTEX_PROVIDER"]
    if os.environ.get("WHISPERTEX_DELIMITER"):
        config["delimiter"] = os.environ["WHISPERTEX_DELIMITER"]

    # Automatically set provider based on available key if still default
    if not config["groq_api_key"]:
        if config["openai_api_key"]:
            config["provider"] = "openai"
            config["stt_provider"] = "openai"
        elif config["gemini_api_key"]:
            config["provider"] = "gemini"

    return config

def save_config(new_config: Dict[str, Any]) -> None:
    """Saves configuration to ~/.whispertex/config.json."""
    get_config_dir()
    with open(CONFIG_FILE, "w", encoding="utf-8") as f:
        json.dump(new_config, f, indent=2)

def get_api_key(config: Dict[str, Any], provider: str) -> str:
    """Returns the API key for a specified provider."""
    if provider == "groq":
        return config.get("groq_api_key") or os.environ.get("GROQ_API_KEY", "")
    elif provider == "openai":
        return config.get("openai_api_key") or os.environ.get("OPENAI_API_KEY", "")
    elif provider == "gemini":
        return config.get("gemini_api_key") or os.environ.get("GEMINI_API_KEY", "")
    return ""
