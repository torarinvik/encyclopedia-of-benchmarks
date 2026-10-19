"""Independent oracle for bounded PolyBench Seidel 2D."""
from __future__ import annotations
import math

MAX_N = 6
MAX_TSTEPS = 4


def expected_output(values: list[float]) -> list[float] | None:
    if len(values) != 2:
        return None
    n_value, step_value = values
    if any(not math.isfinite(v) or v != math.trunc(v) for v in values):
        return None
    if not 1 <= n_value <= MAX_N or not 0 <= step_value <= MAX_TSTEPS:
        return None
    n, steps = int(n_value), int(step_value)
    a = [[(float(i) * float(j + 2) + 2.0) / float(n) for j in range(n)] for i in range(n)]
    for _ in range(steps):
        for i in range(1, n - 1):
            for j in range(1, n - 1):
                total = a[i - 1][j - 1]
                total += a[i - 1][j]
                total += a[i - 1][j + 1]
                total += a[i][j - 1]
                total += a[i][j]
                total += a[i][j + 1]
                total += a[i + 1][j - 1]
                total += a[i + 1][j]
                total += a[i + 1][j + 1]
                a[i][j] = total / 9.0
    return [a[i][j] for i in range(n) for j in range(n)]
