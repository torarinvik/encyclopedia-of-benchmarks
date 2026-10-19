"""Reference model for the bounded PolyBench/C SYRK kernel."""

from __future__ import annotations

import math

MAX_N = 8
MAX_M = 16
MAX_OUTPUT_ELEMENTS = MAX_N * MAX_N
MAX_INPUT_LENGTH = 2
INVALID_RESULT = -1


def expected_output(values: list[float] | tuple[float, ...]) -> list[float] | None:
    """Return the complete row-major C matrix, or None for invalid dimensions."""
    if (not isinstance(values, (list, tuple)) or len(values) != MAX_INPUT_LENGTH
            or any(type(value) not in (int, float) or not math.isfinite(float(value))
                   for value in values)):
        return None
    n_value, m_value = (float(value) for value in values)
    if (not n_value.is_integer() or not m_value.is_integer()
            or not 1 <= n_value <= MAX_N or not 1 <= m_value <= MAX_M):
        return None
    n, m = int(n_value), int(m_value)

    alpha, beta = 1.5, 1.2
    a = [0.0] * (n * m)
    c = [0.0] * (n * n)
    for i in range(n):
        for k in range(m):
            a[i * m + k] = ((i * k + 1) % n) / n
    for i in range(n):
        for j in range(n):
            c[i * n + j] = ((i * j + 2) % m) / m

    for i in range(n):
        for j in range(i + 1):
            c[i * n + j] *= beta
        for k in range(m):
            for j in range(i + 1):
                c[i * n + j] += alpha * a[i * m + k] * a[j * m + k]
    return c
