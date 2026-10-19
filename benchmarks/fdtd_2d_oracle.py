"""Independent reference for the bounded PolyBench FDTD 2D kernel."""
from __future__ import annotations

import math

MAX_TMAX, MAX_NX, MAX_NY = 4, 6, 6
MAX_INPUT_LENGTH = 3
MAX_OUTPUT_ELEMENTS = 3 * MAX_NX * MAX_NY
INVALID_RESULT = -1
OUTPUT_ERROR = -2


def expected_output(values: list[float]) -> list[float] | None:
    if len(values) != MAX_INPUT_LENGTH:
        return None
    tmax, nx, ny = values
    if any(not math.isfinite(v) or v != math.trunc(v) for v in values):
        return None
    if not (0 <= tmax <= MAX_TMAX and 1 <= nx <= MAX_NX and 1 <= ny <= MAX_NY):
        return None
    steps, rows, cols = int(tmax), int(nx), int(ny)
    fict = [float(t) for t in range(steps)]
    ex = [[float(i * (j + 1)) / float(rows) for j in range(cols)] for i in range(rows)]
    ey = [[float(i * (j + 2)) / float(cols) for j in range(cols)] for i in range(rows)]
    hz = [[float(i * (j + 3)) / float(rows) for j in range(cols)] for i in range(rows)]
    for t in range(steps):
        for j in range(cols):
            ey[0][j] = fict[t]
        for i in range(1, rows):
            for j in range(cols):
                ey[i][j] = ey[i][j] - 0.5 * (hz[i][j] - hz[i - 1][j])
        for i in range(rows):
            for j in range(1, cols):
                ex[i][j] = ex[i][j] - 0.5 * (hz[i][j] - hz[i][j - 1])
        for i in range(rows - 1):
            for j in range(cols - 1):
                delta = (ex[i][j + 1] - ex[i][j]) + (ey[i + 1][j] - ey[i][j])
                hz[i][j] = hz[i][j] - 0.7 * delta
    return [v for matrix in (ex, ey, hz) for row in matrix for v in row]
