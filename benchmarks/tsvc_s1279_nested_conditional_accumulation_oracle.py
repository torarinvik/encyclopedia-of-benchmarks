"""Independent bounded oracle for TSVC ControlFlow s1279."""
from __future__ import annotations

import math
from collections.abc import Sequence

MAX_N = 64
MAX_PASSES = 8
MAX_INPUT_LENGTH = 2 + 5 * MAX_N
MAX_OUTPUT_ELEMENTS = MAX_N


def expected_output(values: Sequence[int | float], capacity: int = MAX_OUTPUT_ELEMENTS,
                    output_is_null: bool = False, input_is_null: bool = False,
                    input_length: int | None = None) -> tuple[int, tuple[float, ...]]:
    if input_is_null or not isinstance(values, (list, tuple)):
        return -1, ()
    length = len(values) if input_length is None else input_length
    if (type(length) is not int or length != len(values)
            or length < 7 or length > MAX_INPUT_LENGTH):
        return -1, ()
    if any(type(v) not in (int, float) or not math.isfinite(float(v)) for v in values):
        return -1, ()
    n_raw, passes_raw = float(values[0]), float(values[1])
    if (not n_raw.is_integer() or not 1 <= n_raw <= MAX_N
            or not passes_raw.is_integer() or not 1 <= passes_raw <= MAX_PASSES):
        return -1, ()
    n, passes = int(n_raw), int(passes_raw)
    if length != 2 + 5 * n:
        return -1, ()
    body = [float(v) for v in values[2:]]
    if any(not v.is_integer() or abs(v) > 1 for v in body):
        return -1, ()
    if type(capacity) is not int or capacity < 0:
        return -1, ()
    if output_is_null or capacity < n:
        return -2, ()
    arrays = [body[j*n:(j+1)*n] for j in range(5)]
    a, b, c, d, e = arrays
    for _ in range(passes):
        for i in range(n):
            if a[i] < 0 and b[i] > a[i]:
                c[i] += d[i] * e[i]
    return n, tuple(c)
