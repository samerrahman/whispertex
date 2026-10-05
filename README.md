<div align="center">

# 🎙️ WhisperTeX

**Speak mathematical English. Get clean, precision LaTeX pasted into your active app.**

[![License: MIT](https://img.shields.io/badge/License-MIT-emerald.svg)](LICENSE)
[![Python 3.9+](https://img.shields.io/badge/Python-3.9+-blue.svg)](https://www.python.org/)
[![Status](https://img.shields.io/badge/Status-Active-success.svg)]()

<p align="center">
  <a href="#-quickstart">Quickstart</a> •
  <a href="#-the-problem-whispertex-solves">Why WhisperTeX</a> •
  <a href="#-usage--modes">Usage</a> •
  <a href="#-integrations">Integrations</a> •
  <a href="#-configuration">Configuration</a>
</p>

</div>

---

## 💡 The Problem WhisperTeX Solves

Instead of memorizing tedious voice macros or typing out repetitive syntax (e.g. saying *"backslash f-r-a-c open brace..."*), you dictate standard mathematical English as you would speak it to a colleague, and an LLM converts it into precise LaTeX:

| How You Speak | What WhisperTeX Outputs |
| :--- | :--- |
| *"The integral from zero to infinity of x squared times e to the minus x dx equals two"* | $$\int_{0}^{\infty} x^2 e^{-x} \, dx = 2$$ |
| *"manifold M with metric tensor g sub mu nu"* | $$\mathcal{M}, \quad g_{\mu\nu}$$ |
| *"capital G sub mu nu plus capital Lambda times g sub mu nu equals eight pi capital G over c to the fourth times capital T sub mu nu"* | $$G_{\mu\nu} + \Lambda g_{\mu\nu} = \frac{8\pi G}{c^4} T_{\mu\nu}$$ |
| *"i h-bar partial derivative with respect to t of psi equals minus h-bar squared over two m second partial of psi with respect to x squared plus V psi"* | $$i\hbar \frac{\partial \psi}{\partial t} = -\frac{\hbar^2}{2m} \frac{\partial^2 \psi}{\partial x^2} + V\psi$$ |
| *"bra psi H-hat ket psi equals integral of psi star of x H-hat psi of x dx"* | $$\langle \psi \vert \hat{H} \vert \psi \rangle = \int \psi^*(x) \hat{H} \psi(x) \, dx$$ |

### Why it works so well for advanced math
LLMs understand mathematical context. If you say *"manifold M with metric tensor g sub mu nu"*, it correctly resolves Greek characters, indices, and typographical conventions ($\mathcal{M}$, $g_{\mu\nu}$) without stumbling over literal words.

---

## ⚡ Quickstart

### 1. Installation

Install directly from GitHub using `pip`:

```bash
pip install git+https://github.com/samerrahman/whispertex.git
```

Or clone the repository locally:

```bash
git clone https://github.com/samerrahman/whispertex.git
cd whispertex
pip install -e .
```

*(Optional: For the background global hotkey daemon, install `pip install "whispertex[hotkey]"` or `pip install pynput`)*

---

### 2. Configure Your API Key (Recommended: Groq or OpenAI)

Groq provides ultra-fast (<250ms) inference on Whisper and Llama 3.3 with a generous free tier:

```bash
# Option A: Terminal environment variable
export GROQ_API_KEY="gsk_..."

# Option B: Save permanently in WhisperTeX config
whispertex config --groq-key "gsk_..."
```

*(You can also use OpenAI `export OPENAI_API_KEY="sk_..."` or Google Gemini `export GEMINI_API_KEY="AIzaSy..."`)*

---

## 🚀 Usage & Modes

### 1. Interactive Dictation (`whispertex`)

Run `whispertex` in your terminal, press **Enter**, speak your formula, and press **Enter** to stop.

```bash
whispertex
```

```text
============================================================
 🎙️  WhisperTeX - Interactive Math Dictation
 STT: groq | LLM: groq | Delimiter: display
============================================================

Press [ENTER] to start recording your mathematical formula...
🔴 Recording... Speak standard mathematical English
Press [ENTER] when finished speaking...
⏹️ Stopped recording. Transcribing audio...

🗣️  Spoken: "The integral from zero to infinity of x squared times e to the minus x dx equals two"
⚡ Compiling precision LaTeX...

────────────────────────────────────────
✨ Output LaTeX:
────────────────────────────────────────
$$
\int_{0}^{\infty} x^2 e^{-x} \, dx = 2
$$
────────────────────────────────────────

📋 Copied to clipboard!
🚀 Auto-pasted into active window!
```

WhisperTeX automatically copies the LaTeX to your clipboard and **pastes it directly into whatever app has focus** (Overleaf, VS Code, Obsidian, Notion, Cursor, Slack, Typora)!

---

### 2. Direct CLI Conversion (`whispertex convert`)

Convert any mathematical phrase directly from the terminal without recording audio:

```bash
whispertex convert "the integral from zero to infinity of x squared times e to the minus x dx equals two"
```

Customize delimiters on the fly:
```bash
# Inline math ($...$)
whispertex convert "manifold M with metric tensor g sub mu nu" -d inline

# Raw LaTeX (no delimiters)
whispertex convert "alpha squared plus beta squared" -d raw
```

---

### 3. Background Push-to-Talk Daemon (`whispertex daemon`)

Run WhisperTeX as a background daemon bound to a global hotkey (default: `Cmd+Shift+L`):

```bash
whispertex daemon
```

Whenever you are working in **Overleaf, Obsidian, or VS Code**:
1. Press `Cmd+Shift+L`
2. Speak your formula in natural mathematical English
3. Release or press the hotkey again
4. The LaTeX formula is compiled and automatically typed into your document!

---

### 4. Interactive Benchmark Demo (`whispertex demo`)

Run the built-in capabilities demo across mathematical disciplines (Calculus, Differential Geometry, Quantum Mechanics, Linear Algebra, Probability):

```bash
whispertex demo
```

---

## 🔌 Integrations

### Raycast AI Command
Import our ready-to-use configuration in [`integrations/raycast_command.json`](integrations/raycast_command.json) to trigger spoken LaTeX directly from Raycast.

### Superwhisper / MacWhisper
See [`integrations/README.md`](integrations/README.md) to add WhisperTeX's mathematical system prompt as a custom AI Mode in Superwhisper or MacWhisper.

---

## ⚙️ Configuration

View current configuration:
```bash
whispertex config --show
```

Update settings:
```bash
# Change LLM provider (groq | openai | gemini | ollama | offline)
whispertex config --provider groq

# Change default delimiter (display | inline | bracket | raw)
whispertex config --delimiter inline

# Enable or disable auto-paste
whispertex config --auto-paste true
```

---

## 🧪 Testing

Run the test suite:
```bash
python3 -m unittest discover -s tests
```

---

## 📄 License

MIT © [Samer Rahman](https://github.com/samerrahman)
