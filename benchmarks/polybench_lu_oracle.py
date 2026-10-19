"""Independent reference for the bounded PolyBench LU package."""
from __future__ import annotations
import math

MAX_N = 6


def expected_output(values: list[float]) -> list[float] | None:
    if len(values) != 1:
        return None
    size = values[0]
    if not math.isfinite(size) or size != math.trunc(size) or not 1 <= size <= MAX_N:
        return None
    n = int(size)
    base = [[0.0 for _ in range(n)] for _ in range(n)]
    for i in range(n):
        for j in range(i + 1):
            # In C, (-j % n) is negative for 0 < j < n (truncating remainder).
            base[i][j] = 1.0 - float(j) / float(n)
        base[i][i] = 1.0
    gram = [[0.0 for _ in range(n)] for _ in range(n)]
    for t in range(n):
        for r in range(n):
            for s in range(n):
                gram[r][s] += base[r][t] * base[s][t]
    a = gram
    for i in range(n):
        for j in range(i):
            for k in range(j):
                a[i][j] -= a[i][k] * a[k][j]
            a[i][j] /= a[j][j]
        for j in range(i, n):
            for k in range(i):
                a[i][j] -= a[i][k] * a[k][j]
    return [a[i][j] for i in range(n) for j in range(n)]
