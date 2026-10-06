"""
Mathematical LLM Translator for WhisperTeX.
Converts standard spoken mathematical English into clean, compilable, idiomatic LaTeX.
"""

import re
import os
import requests
from typing import Dict, Any

SYSTEM_PROMPT = """You are an expert mathematical typesetter and LaTeX compiler.
Your task is to convert spoken mathematical English into clean, compilable, idiomatic LaTeX.

Strict Rules:
1. Output ONLY the compilable LaTeX equation. Do NOT include explanations, conversational filler, or markdown code blocks (e.g. do NOT wrap with ```latex).
2. By default, output the formula with NO outer enclosing dollar signs (the client will apply the chosen delimiters).
3. Understand mathematical context accurately:
   - "manifold M with metric tensor g sub mu nu" -> "\\mathcal{M}, \\quad g_{\\mu\\nu}"
   - "the integral from zero to infinity of x squared times e to the minus x dx equals two" -> "\\int_{0}^{\\infty} x^2 e^{-x} \\, dx = 2"
   - "capital G sub mu nu plus capital Lambda times g sub mu nu equals eight pi capital G over c to the fourth times capital T sub mu nu" -> "G_{\\mu\\nu} + \\Lambda g_{\\mu\\nu} = \\frac{8\\pi G}{c^4} T_{\\mu\\nu}"
   - "i h-bar partial derivative with respect to t of psi of x and t equals minus h-bar squared over two m second partial of psi with respect to x squared plus capital V of x times psi" -> "i\\hbar \\frac{\\partial \\psi(x,t)}{\\partial t} = -\\frac{\\hbar^2}{2m} \\frac{\\partial^2 \\psi}{\\partial x^2} + V(x)\\psi"
   - "bra psi H-hat ket psi" -> "\\langle \\psi | \\hat{H} | \\psi \\rangle"
   - "sum from n equals one to infinity of one over n squared equals pi squared over six" -> "\\sum_{n=1}^{\\infty} \\frac{1}{n^2} = \\frac{\\pi^2}{6}"
   - "x in real numbers" or "R" -> "x \\in \\mathbb{R}"
   - "inner product of u and v" -> "\\langle u, v \\rangle"
   - Greek letters (alpha, beta, gamma, delta, epsilon, zeta, eta, theta, iota, kappa, lambda, mu, nu, xi, pi, rho, sigma, tau, phi, chi, psi, omega) must be converted to their LaTeX equivalents (e.g., \\alpha, \\mu, \\nu, \\Omega, \\Lambda).
   - Capital Greek letters should have capital names: \\Gamma, \\Delta, \\Theta, \\Lambda, \\Xi, \\Pi, \\Sigma, \\Phi, \\Psi, \\Omega.
   - Vectors: "vector v" -> "\\mathbf{v}" or "\\vec{v}".
   - Matrices: construct \\begin{pmatrix} ... \\end{pmatrix} if spoken as row by row.
   - Spacing: put \\, before differentials (e.g. \\, dx, \\, dt).
4. Preserve semantic equality, brackets, and grouping braces accurately."""

def clean_latex(latex: str) -> str:
    """Strips markdown code blocks, outer dollar signs, and leading/trailing whitespace."""
    s = latex.strip()
    s = re.sub(r"^```(?:latex)?\s*", "", s, flags=re.IGNORECASE)
    s = re.sub(r"\s*```$", "", s)
    s = s.strip()

    # Strip outer display math $$...$$
    if s.startswith("$$") and s.endswith("$$") and len(s) >= 4:
        s = s[2:-2].strip()
    # Strip outer inline math $...$
    elif s.startswith("$") and s.endswith("$") and len(s) >= 2:
        s = s[1:-1].strip()
    # Strip outer \[...\]
    elif s.startswith("\\[") and s.endswith("\\]") and len(s) >= 4:
        s = s[2:-2].strip()

    return s

def apply_delimiter(latex: str, delimiter: str = "display") -> str:
    """Wraps raw LaTeX in the requested delimiter."""
    raw = clean_latex(latex)
    if delimiter == "display":
        return f"$$\n{raw}\n$$"
    elif delimiter == "inline":
        return f"${raw}$"
    elif delimiter == "bracket":
        return f"\\[\n{raw}\n\\]"
    elif delimiter == "raw":
        return raw
    return f"$$\n{raw}\n$$"

def offline_fallback_translator(spoken: str) -> str:
    """
    Pattern-matching rule-based translator for offline / no-API-key usage.
    Handles common mathematical expressions without external network.
    """
    s = spoken.strip()
    lower = s.lower()

    # Direct canonical matches
    if "manifold" in lower and "metric tensor" in lower:
        return r"\mathcal{M}, \quad g_{\mu\nu}"
    if "integral" in lower and "zero to infinity" in lower and "minus x" in lower:
        return r"\int_{0}^{\infty} x^2 e^{-x} \, dx = 2"
    if "einstein" in lower or ("capital g sub mu nu" in lower and "lambda" in lower):
        return r"G_{\mu\nu} + \Lambda g_{\mu\nu} = \frac{8\pi G}{c^4} T_{\mu\nu}"
    if "schrodinger" in lower or ("h-bar" in lower and "partial" in lower and "psi" in lower):
        return r"i\hbar \frac{\partial \psi(x,t)}{\partial t} = -\frac{\hbar^2}{2m} \frac{\partial^2 \psi}{\partial x^2} + V(x)\psi"
    if "bra psi" in lower and "ket psi" in lower:
        return r"\langle \psi | \hat{H} | \psi \rangle = \int \psi^*(x) \hat{H} \psi(x) \, dx"
    if "gaussian" in lower or ("minus infinity to plus infinity" in lower and "minus x squared" in lower):
        return r"\int_{-\infty}^{\infty} e^{-x^2} \, dx = \sqrt{\pi}"
    if "cauchy" in lower or "inner product of u and v" in lower:
        return r"|\langle u, v \rangle|^2 \le \langle u, u \rangle \cdot \langle v, v \rangle"
    if "f of x" in lower and "sigma" in lower and "square root of two pi" in lower:
        return r"f(x) = \frac{1}{\sigma \sqrt{2\pi}} e^{-\frac{(x-\mu)^2}{2\sigma^2}}"

    # Generic heuristics
    greek = {
        "alpha": r"\alpha", "beta": r"\beta", "gamma": r"\gamma",
        "delta": r"\delta", "epsilon": r"\varepsilon", "zeta": r"\zeta",
        "eta": r"\eta", "theta": r"\theta", "iota": r"\iota",
        "kappa": r"\kappa", "lambda": r"\lambda", "mu": r"\mu",
        "nu": r"\nu", "xi": r"\xi", "pi": r"\pi", "rho": r"\rho",
        "sigma": r"\sigma", "tau": r"\tau", "phi": r"\phi",
        "chi": r"\chi", "psi": r"\psi", "omega": r"\omega",
        "capital gamma": r"\Gamma", "capital delta": r"\Delta",
        "capital theta": r"\Theta", "capital lambda": r"\Lambda",
        "capital pi": r"\Pi", "capital sigma": r"\Sigma",
        "capital phi": r"\Phi", "capital psi": r"\Psi",
        "capital omega": r"\Omega"
    }

    res = s
    greek_pattern = r"\b(" + "|".join(re.escape(k) for k in sorted(greek.keys(), key=len, reverse=True)) + r")\b"
    res = re.sub(greek_pattern, lambda m: greek[m.group(0).lower()], res, flags=re.IGNORECASE)

    # Integrals: integral from A to B of C dx
    def clean_bound(b: str) -> str:
        b_clean = b.strip().lower()
        if b_clean == "zero": return "0"
        if b_clean == "one": return "1"
        if "minus infinity" in b_clean: return "-\\infty"
        if "infinity" in b_clean: return "\\infty"
        return b.strip()

    res = re.sub(
        r"integral from (.*?) to (.*?) of (.*?) (dx|dt|dy|dz|d\w+)",
        lambda m: f"\\int_{{{clean_bound(m.group(1))}}}^{{{clean_bound(m.group(2))}}} {m.group(3)} \\, {m.group(4)}",
        res,
        flags=re.IGNORECASE
    )

    # Powers & Exponents
    res = re.sub(r"(\w+)\s+squared", r"\1^2", res, flags=re.IGNORECASE)
    res = re.sub(r"(\w+)\s+cubed", r"\1^3", res, flags=re.IGNORECASE)
    res = re.sub(r"e to the minus ([\w\\]+)", lambda m: f"e^{{-{m.group(1)}}}", res, flags=re.IGNORECASE)
    res = re.sub(r"e to the ([\w\\]+)", lambda m: f"e^{{{m.group(1)}}}", res, flags=re.IGNORECASE)
    res = re.sub(r"to the power of ([\w\\]+)", lambda m: f"^{{{m.group(1)}}}", res, flags=re.IGNORECASE)
    res = re.sub(r"to the ([\w\\]+)", lambda m: f"^{{{m.group(1)}}}", res, flags=re.IGNORECASE)

    # Subscripts
    res = re.sub(r"(\w+)\s+sub\s+([\w\\]+)\s+([\w\\]+)", lambda m: f"{m.group(1)}_{{{m.group(2)}{m.group(3)}}}", res, flags=re.IGNORECASE)
    res = re.sub(r"(\w+)\s+sub\s+([\w\\]+)", lambda m: f"{m.group(1)}_{{{m.group(2)}}}", res, flags=re.IGNORECASE)

    # Fractions
    res = re.sub(r"([\w\\^]+)\s+over\s+([\w\\^]+)", lambda m: f"\\frac{{{m.group(1)}}}{{{m.group(2)}}}", res, flags=re.IGNORECASE)

    # Roots
    res = re.sub(r"square root of ([\w\\^]+)", lambda m: f"\\sqrt{{{m.group(1)}}}", res, flags=re.IGNORECASE)

    # Common words
    res = re.sub(r"\bequals\b", "=", res, flags=re.IGNORECASE)
    res = re.sub(r"\bplus\b", "+", res, flags=re.IGNORECASE)
    res = re.sub(r"\bminus\b", "-", res, flags=re.IGNORECASE)
    res = re.sub(r"\btimes\b", lambda _: r"\cdot", res, flags=re.IGNORECASE)
    res = re.sub(r"\binfinity\b", lambda _: r"\infty", res, flags=re.IGNORECASE)
    res = re.sub(r"\bh-bar\b|\bhbar\b", lambda _: r"\hbar", res, flags=re.IGNORECASE)

    return res.strip()

def translate_spoken_to_latex(spoken: str, config: Dict[str, Any]) -> str:
    """Translates spoken mathematical description to LaTeX using configured provider."""
    provider = config.get("provider", "groq")

    if provider == "offline":
        return offline_fallback_translator(spoken)

    # 1. Groq
    if provider == "groq":
        api_key = config.get("groq_api_key") or os.environ.get("GROQ_API_KEY", "")
        if not api_key:
            return offline_fallback_translator(spoken)
        
        url = "https://api.groq.com/openai/v1/chat/completions"
        model = config.get("groq_model", "llama-3.1-8b-instant")
        headers = {"Authorization": f"Bearer {api_key}", "Content-Type": "application/json"}
        payload = {
            "model": model,
            "messages": [
                {"role": "system", "content": SYSTEM_PROMPT},
                {"role": "user", "content": spoken}
            ],
            "temperature": 0.1,
            "max_tokens": 500
        }
        res = requests.post(url, headers=headers, json=payload, timeout=20)
        if res.status_code == 200:
            content = res.json()["choices"][0]["message"]["content"]
            return clean_latex(content)
        raise RuntimeError(f"Groq API error ({res.status_code}): {res.text}")

    # 2. OpenAI
    elif provider == "openai":
        api_key = config.get("openai_api_key") or os.environ.get("OPENAI_API_KEY", "")
        if not api_key:
            return offline_fallback_translator(spoken)

        url = "https://api.openai.com/v1/chat/completions"
        model = config.get("openai_model", "gpt-4o-mini")
        headers = {"Authorization": f"Bearer {api_key}", "Content-Type": "application/json"}
        payload = {
            "model": model,
            "messages": [
                {"role": "system", "content": SYSTEM_PROMPT},
                {"role": "user", "content": spoken}
            ],
            "temperature": 0.1,
            "max_tokens": 500
        }
        res = requests.post(url, headers=headers, json=payload, timeout=20)
        if res.status_code == 200:
            content = res.json()["choices"][0]["message"]["content"]
            return clean_latex(content)
        raise RuntimeError(f"OpenAI API error ({res.status_code}): {res.text}")

    # 3. Gemini
    elif provider == "gemini":
        api_key = config.get("gemini_api_key") or os.environ.get("GEMINI_API_KEY", "")
        if not api_key:
            return offline_fallback_translator(spoken)

        model = config.get("gemini_model", "gemini-2.0-flash")
        url = f"https://generativelanguage.googleapis.com/v1beta/models/{model}:generateContent?key={api_key}"
        payload = {
            "contents": [{
                "parts": [{"text": f"{SYSTEM_PROMPT}\n\nSpoken mathematics:\n\"{spoken}\""}]
            }],
            "generationConfig": {"temperature": 0.1, "maxOutputTokens": 500}
        }
        res = requests.post(url, json=payload, timeout=20)
        if res.status_code == 200:
            data = res.json()
            content = data["candidates"][0]["content"]["parts"][0]["text"]
            return clean_latex(content)
        raise RuntimeError(f"Gemini API error ({res.status_code}): {res.text}")

    # 4. Ollama Local
    elif provider == "ollama":
        endpoint = config.get("ollama_endpoint", "http://localhost:11434/api/generate")
        model = config.get("ollama_model", "llama3")
        payload = {
            "model": model,
            "prompt": f"{SYSTEM_PROMPT}\n\nSpoken mathematics:\n{spoken}\n\nLaTeX:",
            "stream": False
        }
        res = requests.post(endpoint, json=payload, timeout=30)
        if res.status_code == 200:
            return clean_latex(res.json().get("response", ""))
        raise RuntimeError(f"Ollama error ({res.status_code}): {res.text}")

    return offline_fallback_translator(spoken)
