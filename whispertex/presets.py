"""
Curated math presets for testing, benchmarking, and demonstration.
"""

from typing import List, Dict

PRESETS: List[Dict[str, str]] = [
    {
        "title": "Gamma Function Integral",
        "category": "Calculus",
        "spoken": "The integral from zero to infinity of x squared times e to the minus x dx equals two",
        "expected": r"\int_{0}^{\infty} x^2 e^{-x} \, dx = 2",
        "description": "Definite bounds, exponential decay, powers, and differential."
    },
    {
        "title": "Manifold Metric Tensor",
        "category": "Differential Geometry",
        "spoken": "manifold M with metric tensor g sub mu nu",
        "expected": r"\mathcal{M}, \quad g_{\mu\nu}",
        "description": "Calligraphic manifold symbol and Greek covariant tensor indices."
    },
    {
        "title": "Einstein Field Equations",
        "category": "General Relativity",
        "spoken": "capital G sub mu nu plus capital Lambda times g sub mu nu equals eight pi capital G over c to the fourth times capital T sub mu nu",
        "expected": r"G_{\mu\nu} + \Lambda g_{\mu\nu} = \frac{8\pi G}{c^4} T_{\mu\nu}",
        "description": "Relativity field equation with cosmological constant and energy-momentum tensor."
    },
    {
        "title": "Time-Dependent Schrödinger Equation",
        "category": "Quantum Mechanics",
        "spoken": "i h-bar partial derivative with respect to t of psi of x and t equals minus h-bar squared over two m second partial of psi with respect to x squared plus capital V of x times psi",
        "expected": r"i\hbar \frac{\partial \psi(x,t)}{\partial t} = -\frac{\hbar^2}{2m} \frac{\partial^2 \psi}{\partial x^2} + V(x)\psi",
        "description": "Reduced Planck constant, partial derivatives, and wave function."
    },
    {
        "title": "Gaussian Integral",
        "category": "Calculus",
        "spoken": "integral from minus infinity to plus infinity of e to the minus x squared dx equals square root of pi",
        "expected": r"\int_{-\infty}^{\infty} e^{-x^2} \, dx = \sqrt{\pi}",
        "description": "Symmetric infinite limits with exponential squared."
    },
    {
        "title": "Dirac Bra-Ket & Hamiltonian",
        "category": "Quantum Mechanics",
        "spoken": "bra psi H-hat ket psi equals integral of psi star of x H-hat psi of x dx",
        "expected": r"\langle \psi | \hat{H} | \psi \rangle = \int \psi^*(x) \hat{H} \psi(x) \, dx",
        "description": "Bra-ket notation, operator hat, complex conjugate."
    },
    {
        "title": "Cauchy-Schwarz Inequality",
        "category": "Linear Algebra",
        "spoken": "absolute value of inner product of u and v squared is less than or equal to inner product of u and u times inner product of v and v",
        "expected": r"|\langle u, v \rangle|^2 \le \langle u, u \rangle \cdot \langle v, v \rangle",
        "description": "Inner product spaces and vector inequality."
    },
    {
        "title": "Gaussian / Normal PDF",
        "category": "Probability & Statistics",
        "spoken": "f of x equals one over sigma square root of two pi times e to the minus open paren x minus mu close paren squared over two sigma squared",
        "expected": r"f(x) = \frac{1}{\sigma \sqrt{2\pi}} e^{-\frac{(x-\mu)^2}{2\sigma^2}}",
        "description": "Normal distribution probability density function."
    }
]
