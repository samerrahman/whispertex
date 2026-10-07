WhisperTeX for Windows — Quickstart Guide
=========================================

WhisperTeX lets you dictate mathematical English and automatically pastes
clean LaTeX wherever your cursor is blinking (Overleaf, Notion, Google Docs, Word, VS Code).

Requirements:
- Windows 10 or 11 (64-bit)
- Python 3.9+ (make sure "Add Python to PATH" was checked during Python installation)
- An API Key: Free Groq API Key (https://console.groq.com/keys) or OpenAI API Key

How to Run:
1. Double-click "run_whispertex.bat".
2. Enter your API key when prompted (or set it in Windows environment variables: setx GROQ_API_KEY "gsk_...").
3. Press [Ctrl + Alt + L] anywhere across Windows:
   - Speak your formula (e.g. "integral from zero to infinity of x squared e to the minus x dx")
   - Press [Ctrl + Alt + L] again to stop.
   - WhisperTeX translates it and automatically simulates Ctrl+V into your active text editor!

Alternative CLI Usage (PowerShell or Command Prompt):
   pip install git+https://github.com/samerrahman/whispertex.git
   set GROQ_API_KEY=gsk_...
   whispertex daemon

Website: https://whispertex.dev
GitHub: https://github.com/samerrahman/whispertex
