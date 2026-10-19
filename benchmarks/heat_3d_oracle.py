"""Independent reference for the bounded PolyBench heat-3d kernel."""
from __future__ import annotations
import math

MAX_N = 6
MAX_TSTEPS = 4
MAX_INPUT_LENGTH = 2
MAX_OUTPUT_ELEMENTS = MAX_N * MAX_N * MAX_N
INVALID_RESULT = -1
OUTPUT_ERROR = -2


def expected_output(values: list[float]) -> list[float] | None:
    if len(values) != MAX_INPUT_LENGTH:
        return None
    n_value, t_value = values
    if any(not math.isfinite(v) or v != math.trunc(v) for v in values):
        return None
    if not 1 <= n_value <= MAX_N or not 0 <= t_value <= MAX_TSTEPS:
        return None
    n, steps = int(n_value), int(t_value)
    a = [[[(float(i + j + (n - k)) * 10.0) / float(n) for k in range(n)]
          for j in range(n)] for i in range(n)]
    b = [[row[:] for row in plane] for plane in a]
    for _ in range(steps):
        for i in range(1, n - 1):
            for j in range(1, n - 1):
                for k in range(1, n - 1):
                    center = a[i][j][k]
                    x = 0.125 * (a[i + 1][j][k] - 2.0 * center + a[i - 1][j][k])
                    y = 0.125 * (a[i][j + 1][k] - 2.0 * center + a[i][j - 1][k])
                    z = 0.125 * (a[i][j][k + 1] - 2.0 * center + a[i][j][k - 1])
                    b[i][j][k] = ((x + y) + z) + center
        for i in range(1, n - 1):
            for j in range(1, n - 1):
                for k in range(1, n - 1):
                    center = b[i][j][k]
                    x = 0.125 * (b[i + 1][j][k] - 2.0 * center + b[i - 1][j][k])
                    y = 0.125 * (b[i][j + 1][k] - 2.0 * center + b[i][j - 1][k])
                    z = 0.125 * (b[i][j][k + 1] - 2.0 * center + b[i][j][k - 1])
                    a[i][j][k] = ((x + y) + z) + center
    return [a[i][j][k] for i in range(n) for j in range(n) for k in range(n)]
