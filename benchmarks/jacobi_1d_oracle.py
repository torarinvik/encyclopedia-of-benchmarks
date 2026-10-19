"""Independent reference for the bounded PolyBench/C jacobi-1d stencil."""

from __future__ import annotations

import math

MAX_N = 30
MAX_TSTEPS = 20
MAX_PARSEABLE_INPUT_LENGTH = 3
MAX_OUTPUT_ELEMENTS = MAX_N
INVALID_RESULT = -1
OUTPUT_ERROR = -2


def expected_output(values: list[float]) -> list[float] | None:
    """Return the source-ordered final A vector for input ``[n, tsteps]``."""
    if len(values) != 2:
        return None
    n_value, steps_value = values
    if (not math.isfinite(n_value) or n_value != math.trunc(n_value)
            or not 1 <= n_value <= MAX_N):
        return None
    if (not math.isfinite(steps_value) or steps_value != math.trunc(steps_value)
            or not 0 <= steps_value <= MAX_TSTEPS):
        return None

    n = int(n_value)
    steps = int(steps_value)
    a = [(float(i) + 2.0) / float(n) for i in range(n)]
    b = [(float(i) + 3.0) / float(n) for i in range(n)]
    for _ in range(steps):
        for i in range(1, n - 1):
            b[i] = 0.33333 * (a[i - 1] + a[i] + a[i + 1])
        for i in range(1, n - 1):
            a[i] = 0.33333 * (b[i - 1] + b[i] + b[i + 1])
    return a
