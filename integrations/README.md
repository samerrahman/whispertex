# 🔌 Third-Party Integrations

You can use WhisperTeX directly via the CLI (`whispertex`) or global daemon (`whispertex daemon`). If you prefer integrating into existing macOS productivity launchers, here is how:

---

## 1. Raycast AI Command
1. Open Raycast &rarr; Search **"Create AI Command"**.
2. Name: **"Spoken Math to LaTeX"**.
3. System Prompt:
   ```text
   Convert the following spoken description of mathematical expressions into clean, compilable LaTeX. Output only the LaTeX equation enclosed in $$ or $.
   ```
4. Bind to a hotkey (e.g., `Option + Space` or `Cmd + Shift + L`).

---

## 2. Superwhisper / MacWhisper
1. Open **Superwhisper Settings** &rarr; **Modes** &rarr; **New Mode**.
2. Select **Groq (llama-3.3-70b)** or **OpenAI (gpt-4o-mini)**.
3. Paste the prompt from `superwhisper_mode.json`.
4. Output setting: **Replace Selection** or **Insert at Cursor**.
5. Hold your push-to-talk key, speak math, and it inserts clean LaTeX directly into Overleaf, Obsidian, or VS Code!
