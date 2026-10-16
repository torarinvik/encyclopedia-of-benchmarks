"""Independent oracle for the bounded real Rayleigh quotient."""

from __future__ import annotations

import math


def expected_result(values: list[float] | tuple[float, ...]) -> list[float] | None:
    """Return the single Rayleigh quotient output for a valid encoded input."""
    if not isinstance(values, (list, tuple)) or not values:
        return None
    if any(type(value) not in (int, float) for value in values):
        return None
    if any(not math.isfinite(float(value)) for value in values):
        return None
    n_value = float(values[0])
    if not n_value.is_integer() or not 1.0 <= n_value <= 16.0:
        return None
    n = int(n_value)
    if len(values) != 1 + n * n + n:
        return None
    matrix = [float(value) for value in values[1 : 1 + n * n]]
    vector = [float(value) for value in values[1 + n * n :]]
    if any(value < -1000.0 or value > 1000.0 for value in matrix):
        return None
    if any(value < -100.0 or value > 100.0 for value in vector):
        return None
    for row in range(n):
        for col in range(row + 1, n):
            if matrix[row * n + col] != matrix[col * n + row]:
                return None

    denominator = 0.0
    for value in vector:
        denominator += value * value
    if denominator <= 0.0 or not math.isfinite(denominator):
        return None

    # Match the source's v.T @ A followed by the row-vector dot with v.
    v_star_dot = [0.0] * n
    for col in range(n):
        total = 0.0
        for row in range(n):
            total += vector[row] * matrix[row * n + col]
        v_star_dot[col] = total
    numerator = 0.0
    for col in range(n):
        numerator += v_star_dot[col] * vector[col]
    return [numerator / denominator]
