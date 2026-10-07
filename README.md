<div align="center">

# 🎙️ WhisperTeX

**Dictate standard mathematical English. WhisperTeX types clean, precision LaTeX wherever your cursor is blinking.**

*Available for macOS & Windows • Native Menu Bar & Background Hotkey Daemon*

[![Website](https://img.shields.io/badge/Website-whispertex.dev-emerald?style=for-the-badge&logo=safari)](https://whispertex.dev)
[![Download Mac](https://img.shields.io/badge/Download-macOS%20.dmg-blue?style=for-the-badge&logo=apple)](https://github.com/samerrahman/whispertex/releases/latest/download/WhisperTeX-macos.dmg)
[![Download Windows](https://img.shields.io/badge/Download-Windows%20.zip-0078D6?style=for-the-badge&logo=windows)](https://github.com/samerrahman/whispertex/releases/latest/download/WhisperTeX-windows-x64.zip)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)

</div>

---

> This project is a work in progress and may not be totally functional. Expect bugs.

## What it does

Instead of memorizing voice macros or typing out backslashes and brackets by hand, you speak the formula normally and an LLM converts it into LaTeX:

| Spoken English | Output LaTeX |
| :--- | :--- |
| "The integral from zero to infinity of x squared times e to the minus x dx equals two" | `$$\int_{0}^{\infty} x^2 e^{-x} \, dx = 2$$` |
| "manifold M with metric tensor g sub mu nu" | `$$\mathcal{M}, \quad g_{\mu\nu}$$` |
| "capital G sub mu nu plus capital Lambda times g sub mu nu equals eight pi capital G over c to the fourth times capital T sub mu nu" | `$$G_{\mu\nu} + \Lambda g_{\mu\nu} = \frac{8\pi G}{c^4} T_{\mu\nu}$$` |
| "i h-bar partial derivative with respect to t of psi equals minus h-bar squared over two m second partial of psi with respect to x squared plus V psi" | `$$i\hbar \frac{\partial \psi}{\partial t} = -\frac{\hbar^2}{2m} \frac{\partial^2 \psi}{\partial x^2} + V\psi$$` |
| "bra psi H-hat ket psi equals integral of psi star of x H-hat psi of x dx" | `$$\langle \psi \vert \hat{H} \vert \psi \rangle = \int \psi^*(x) \hat{H} \psi(x) \, dx$$` |

Because LLMs have mathematical context, things like Greek letters, differential spacing (`\, dx`), and subscripts resolve naturally without having to say "backslash".

---

## Installation

### macOS App (Menu bar + Window)
1. Download [WhisperTeX-macos.dmg](https://github.com/samerrahman/whispertex/releases/latest/download/WhisperTeX-macos.dmg) (or [.zip](https://github.com/samerrahman/whispertex/releases/latest/download/WhisperTeX-macos-arm64.zip)).
2. Drag `WhisperTeX.app` to `/Applications`.
3. Open the app, paste a free [Groq](https://console.groq.com/keys) or OpenAI API key in Settings, and make sure Microphone & Accessibility permissions are enabled.
4. Press `⌘+Shift+L` anywhere on your Mac to start/stop dictating. It copies and simulates `⌘+V` into your active editor (Overleaf, Notion, Google Docs, VS Code, Obsidian, etc.).

### Windows (Portable Package)
1. Download [WhisperTeX-windows-x64.zip](https://github.com/samerrahman/whispertex/releases/latest/download/WhisperTeX-windows-x64.zip) and extract it.
2. Double-click `run_whispertex.bat`.
3. Enter your free [Groq](https://console.groq.com/keys) or OpenAI API key when prompted.
4. Press `Ctrl+Alt+L` anywhere on Windows to start/stop dictating and auto-paste LaTeX at your cursor.

### Python CLI (macOS, Windows & Linux)
```bash
pip install git+https://github.com/samerrahman/whispertex.git
export GROQ_API_KEY="gsk_..."  # on Windows Command Prompt: set GROQ_API_KEY=gsk_...

# Dictate directly from the terminal
whispertex

# Or run background global hotkey daemon
whispertex daemon

# Or convert text directly
whispertex convert "integral from zero to infinity of x squared e to the minus x dx"
```

---

## Building from Source

Requirements: macOS 13+, Swift 5.9+.

```bash
git clone https://github.com/samerrahman/whispertex.git
cd whispertex
./scripts/build_macos_app.sh
```

Build outputs are saved to `dist/WhisperTeX.app` and `dist/WhisperTeX-macos.dmg`.

---

## License

MIT
