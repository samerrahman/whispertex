"""
WhisperTeX: Spoken Mathematical English to Precision LaTeX.
"""

__version__ = "0.1.0"
__author__ = "Samer Rahman"

from whispertex.translator import translate_spoken_to_latex
from whispertex.clipboard import copy_to_clipboard, auto_paste

__all__ = ["translate_spoken_to_latex", "copy_to_clipboard", "auto_paste", "__version__"]
