"""Independent reference for bounded PolyBench/C trisolv."""

from __future__ import annotations

import math

MIN_N = 1
MAX_N = 40
MAX_PARSEABLE_INPUT_LENGTH = 2
INVALID_RESULT = -1
OUTPUT_ERROR = -2


def expected_output(values: list[float]) -> list[float] | None:
    """Return the source-ordered solution vector for input ``[n]``."""
    if len(values) != 1:
        return None
    value = values[0]
    if (not math.isfinite(value) or value != math.trunc(value)
            or not MIN_N <= value <= MAX_N):
        return None

    n = int(value)
    lower = [[0.0] * n for _ in range(n)]
    b = [0.0] * n
    x = [0.0] * n
    for i in range(n):
        b[i] = float(i)
        for j in range(i + 1):
            lower[i][j] = float(i + n - j + 1) * 2.0 / float(n)

    for i in range(n):
        x[i] = b[i]
        for j in range(i):
            x[i] -= lower[i][j] * x[j]
        x[i] /= lower[i][i]
    return x
