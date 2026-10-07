<div align="center">

# 🎙️ WhisperTeX for Mac

**Dictate standard mathematical English. WhisperTeX types clean, precision LaTeX wherever your cursor is blinking.**

*A native macOS Menu Bar application + Python CLI.*

[![Website](https://img.shields.io/badge/Website-whispertex.dev-emerald?style=for-the-badge&logo=safari)](https://whispertex.dev)
[![Download DMG](https://img.shields.io/badge/Download-macOS%20.dmg-blue?style=for-the-badge&logo=apple)](https://github.com/samerrahman/whispertex/releases/latest)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![Platform](https://img.shields.io/badge/Platform-macOS%20%7C%20Linux-lightgrey.svg)]()

<br/>

<p align="center">
  <a href="https://whispertex.dev">🌐 Interactive Web Demo</a> •
  <a href="#-quickstart--download">Download & Install</a> •
  <a href="#-how-it-works">How It Works</a> •
  <a href="#-features">Features</a> •
  <a href="#-cli-usage">Terminal CLI</a> •
  <a href="#-integrations">Integrations</a>
</p>

</div>

---

## 💡 How It Works

Instead of memorizing tedious voice macros or manually typing out repetitive syntax (e.g. saying *"backslash f-r-a-c open brace..."*), you dictate standard mathematical English as you would speak it to a colleague, and an LLM converts it into precise LaTeX:

| What You Speak | Where Your Cursor Types |
| :--- | :--- |
| *"The integral from zero to infinity of x squared times e to the minus x dx equals two"* | $$\int_{0}^{\infty} x^2 e^{-x} \, dx = 2$$ |
| *"manifold M with metric tensor g sub mu nu"* | $$\mathcal{M}, \quad g_{\mu\nu}$$ |
| *"capital G sub mu nu plus capital Lambda times g sub mu nu equals eight pi capital G over c to the fourth times capital T sub mu nu"* | $$G_{\mu\nu} + \Lambda g_{\mu\nu} = \frac{8\pi G}{c^4} T_{\mu\nu}$$ |
| *"i h-bar partial derivative with respect to t of psi equals minus h-bar squared over two m second partial of psi with respect to x squared plus V psi"* | $$i\hbar \frac{\partial \psi}{\partial t} = -\frac{\hbar^2}{2m} \frac{\partial^2 \psi}{\partial x^2} + V\psi$$ |
| *"bra psi H-hat ket psi equals integral of psi star of x H-hat psi of x dx"* | $$\langle \psi \vert \hat{H} \vert \psi \rangle = \int \psi^*(x) \hat{H} \psi(x) \, dx$$ |

### Why it works so well for advanced math
LLMs understand mathematical context. If you say *"manifold M with metric tensor g sub mu nu"*, it correctly resolves Greek characters, subscripts, and typographical conventions ($\mathcal{M}$, $g_{\mu\nu}$) without stumbling over literal words.

---

## ⚡ Quickstart / Download

### Option 1: Native macOS Menu Bar App (Recommended)

1. Download the latest **[WhisperTeX-macos.dmg](https://github.com/samerrahman/whispertex/releases/latest)** (or `.zip`).
2. Drag **`WhisperTeX.app`** into your `/Applications` folder and open it.
3. WhisperTeX appears in your top menu bar as `∫`.
4. Press <kbd>⌘</kbd> + <kbd>Shift</kbd> + <kbd>L</kbd> (or click the menu bar item), speak your mathematical formula, and watch it **type directly into Overleaf, Google Docs, Notion, VS Code, Notes, Obsidian, Slack, or Word**!

---

### Option 2: Python CLI

Install directly via `pip`:

```bash
pip install git+https://github.com/samerrahman/whispertex.git
```

Configure your API key (Groq, OpenAI, or Gemini):

```bash
export GROQ_API_KEY="gsk_..."
# or save permanently:
whispertex config --groq-key "gsk_..."
```

---

## 🌟 Features

- **Lives in the macOS Menu Bar**: Sits unobtrusively in your status bar with an `∫` icon.
- **Global Push-to-Talk Hotkey**: Trigger dictation from anywhere across macOS with <kbd>⌘</kbd> + <kbd>Shift</kbd> + <kbd>L</kbd>.
- **Direct Cursor Typing**: Automatically copies and simulates keystroke paste directly into whatever editor you are currently working in.
- **Live KaTeX Typesetting Preview**: Click the menu bar icon to view an interactive visual popover rendering the mathematical equations in real time.
- **Delimiter Toggles**: Switch between Display math `$$...$$`, Inline math `$ ... $`, Block `\[ ... \]`, or Raw LaTeX with one click.
- **Ultra-low Latency**: Powered by Groq Whisper (`whisper-large-v3`) and Groq Llama 3.3 for sub-300ms total turnaround, with support for OpenAI (`gpt-4o-mini`), Google Gemini (`gemini-2.0-flash`), and an offline fallback parser.
- **Preset Gallery**: One-click test cards across Calculus, Differential Geometry, General Relativity, Quantum Mechanics, and Linear Algebra.

---

## 💻 CLI Usage

If you prefer using the terminal or scripting workflows:

```bash
# 1. Interactive terminal dictation
whispertex

# 2. Convert mathematical text directly
whispertex convert "the integral from zero to infinity of x squared times e to the minus x dx equals two"

# 3. Inline delimiter format ($...$)
whispertex convert "manifold M with metric tensor g sub mu nu" -d inline

# 4. Run capabilities benchmark demo
whispertex demo

# 5. Run background hotkey daemon
whispertex daemon
```

---

## 🛠️ Building the macOS App from Source

WhisperTeX is written in native Swift using SwiftUI and AppKit. To compile locally:

```bash
git clone https://github.com/samerrahman/whispertex.git
cd whispertex
./scripts/build_macos_app.sh
```

The output will be in `dist/WhisperTeX.app`, `dist/WhisperTeX-macos-arm64.zip`, and `dist/WhisperTeX-macos.dmg`.

---

## 🔌 Launcher Integrations

Prefer using Raycast or Superwhisper?
- **Raycast AI**: Import [`integrations/raycast_command.json`](integrations/raycast_command.json).
- **Superwhisper / MacWhisper**: Import [`integrations/superwhisper_mode.json`](integrations/superwhisper_mode.json).

---

## 📄 License

MIT © [Samer Rahman](https://github.com/samerrahman)
