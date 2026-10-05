"""
Unit tests for WhisperTeX translation and formatting functions.
"""

import unittest
from whispertex.translator import (
    clean_latex,
    apply_delimiter,
    offline_fallback_translator,
    translate_spoken_to_latex
)

class TestTranslator(unittest.TestCase):
    def test_clean_latex(self):
        # Strips markdown ticks
        self.assertEqual(clean_latex("```latex\nx^2 + y^2\n```"), "x^2 + y^2")
        # Strips outer $$
        self.assertEqual(clean_latex("$$\\int x dx$$"), "\\int x dx")
        # Strips outer $
        self.assertEqual(clean_latex("$E = mc^2$"), "E = mc^2")
        # Strips outer \[ \]
        self.assertEqual(clean_latex("\\[g_{\\mu\\nu}\\]"), "g_{\\mu\\nu}")

    def test_apply_delimiter(self):
        raw = "\\int x dx"
        self.assertEqual(apply_delimiter(raw, "display"), "$$\n\\int x dx\n$$")
        self.assertEqual(apply_delimiter(raw, "inline"), "$\\int x dx$")
        self.assertEqual(apply_delimiter(raw, "bracket"), "\\[\n\\int x dx\n\\]")
        self.assertEqual(apply_delimiter(raw, "raw"), "\\int x dx")

    def test_user_integral_prompt(self):
        spoken = "The integral from zero to infinity of x squared times e to the minus x dx equals two"
        res = offline_fallback_translator(spoken)
        self.assertEqual(res, r"\int_{0}^{\infty} x^2 e^{-x} \, dx = 2")

    def test_user_manifold_prompt(self):
        spoken = "manifold M with metric tensor g sub mu nu"
        res = offline_fallback_translator(spoken)
        self.assertEqual(res, r"\mathcal{M}, \quad g_{\mu\nu}")

    def test_offline_einstein(self):
        spoken = "capital G sub mu nu plus capital Lambda times g sub mu nu equals eight pi capital G over c to the fourth times capital T sub mu nu"
        res = offline_fallback_translator(spoken)
        self.assertIn("G_{\\mu\\nu}", res)
        self.assertIn("\\Lambda", res)

    def test_translate_offline_mode(self):
        config = {"provider": "offline"}
        res = translate_spoken_to_latex("manifold M with metric tensor g sub mu nu", config)
        self.assertEqual(res, r"\mathcal{M}, \quad g_{\mu\nu}")

if __name__ == "__main__":
    unittest.main()
