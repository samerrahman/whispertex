"""
Unit tests for WhisperTeX config handling.
"""

import os
import unittest
from whispertex.config import load_config, DEFAULT_CONFIG

class TestConfig(unittest.TestCase):
    def test_default_config(self):
        config = load_config()
        self.assertIn("provider", config)
        self.assertIn("delimiter", config)
        self.assertIn(config["delimiter"], ["display", "inline", "bracket", "raw"])

    def test_env_override(self):
        os.environ["WHISPERTEX_DELIMITER"] = "inline"
        config = load_config()
        self.assertEqual(config["delimiter"], "inline")
        del os.environ["WHISPERTEX_DELIMITER"]

if __name__ == "__main__":
    unittest.main()
