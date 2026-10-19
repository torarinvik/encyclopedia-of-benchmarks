"""Independent reference for the bounded PolyBench correlation matrix."""
from __future__ import annotations
import math

MAX_N = 6
MAX_M = 6


def expected_output(values: list[float]) -> list[float] | None:
    if len(values) != 2:
        return None
    n_value, m_value = values
    if any(not math.isfinite(v) or v != math.trunc(v) for v in values):
        return None
    if not 1 <= n_value <= MAX_N or not 1 <= m_value <= MAX_M:
        return None
    n, m = int(n_value), int(m_value)
    float_n = float(n)
    data = [[float(i * j) / float(m) + float(i) for j in range(m)] for i in range(n)]
    means = [0.0] * m
    stddev = [0.0] * m
    for j in range(m):
        for i in range(n):
            means[j] += data[i][j]
        means[j] /= float_n
    for j in range(m):
        for i in range(n):
            delta = data[i][j] - means[j]
            stddev[j] += delta * delta
        stddev[j] /= float_n
        stddev[j] = math.sqrt(stddev[j])
        if stddev[j] <= 0.1:
            stddev[j] = 1.0
    root_n = math.sqrt(float_n)
    for i in range(n):
        for j in range(m):
            data[i][j] -= means[j]
            data[i][j] /= root_n * stddev[j]
    corr = [[0.0] * m for _ in range(m)]
    for i in range(m - 1):
        corr[i][i] = 1.0
        for j in range(i + 1, m):
            corr[i][j] = 0.0
            for k in range(n):
                corr[i][j] += data[k][i] * data[k][j]
            corr[j][i] = corr[i][j]
    corr[m - 1][m - 1] = 1.0
    return [corr[i][j] for i in range(m) for j in range(m)]
