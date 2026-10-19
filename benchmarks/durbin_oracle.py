"""Oracle for the bounded PolyBench Durbin recurrence."""

from __future__ import annotations

import math

MIN_N = 1
# PolyBench's MINI_DATASET uses N=40; accept this deterministic workload bound.
MAX_N = 40


def expected_output(values: list[float]) -> list[float] | None:
    """Return the source-ordered Durbin coefficient vector for input ``[n]``."""
    if len(values) != 1:
        return None
    value = values[0]
    if (not math.isfinite(value) or value != math.trunc(value)
            or not MIN_N <= value <= MAX_N):
        return None

    n = int(value)
    r = [float(n + 1 - i) for i in range(n)]
    y = [0.0] * n
    z = [0.0] * n
    y[0] = -r[0]
    beta = 1.0
    alpha = -r[0]

    for k in range(1, n):
        beta = (1.0 - alpha * alpha) * beta
        total = 0.0
        for i in range(k):
            total += r[k - i - 1] * y[i]
        alpha = -(r[k] + total) / beta
        for i in range(k):
            z[i] = y[i] + alpha * y[k - i - 1]
        for i in range(k):
            y[i] = z[i]
        y[k] = alpha
    return y
