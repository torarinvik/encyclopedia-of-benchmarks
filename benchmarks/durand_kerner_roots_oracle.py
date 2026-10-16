"""Reference Durand–Kerner solver for bounded real cubics x^3 - d."""
from __future__ import annotations

import cmath
import math

INVALID_RESULT = -1.0e300


def roots_for_constant(d: int) -> list[complex]:
    omega = complex(-0.5, math.sqrt(3.0) / 2.0)
    sign = 1.0 if d > 0 else -1.0
    roots = [complex(sign, 0.0), sign * omega, sign * omega.conjugate()]
    for _ in range(100):
        updated = []
        for index, z in enumerate(roots):
            denominator = 1 + 0j
            for other_index, other in enumerate(roots):
                if index != other_index:
                    denominator *= z - other
            updated.append(z - (z**3 - d) / denominator)
        if max(abs(a - b) for a, b in zip(updated, roots)) < 1.0e-14:
            roots = updated
            break
        roots = updated
    return roots


def expected_result(values: list[int] | tuple[int, ...]) -> float:
    if len(values) != 3:
        return INVALID_RESULT
    d, root_index, component = values
    if d == 0 or d < -4 or d > 4 or root_index < 0 or root_index > 2 or component < 0 or component > 1:
        return INVALID_RESULT
    root = roots_for_constant(d)[root_index]
    return root.real if component == 0 else root.imag
