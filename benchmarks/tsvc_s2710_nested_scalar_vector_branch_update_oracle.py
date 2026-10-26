"""Independent oracle for TSVC ControlFlow s2710."""
from __future__ import annotations

import math
from collections.abc import Sequence

MAX_N = 64
MIN_N = 11
MAX_PASSES = 8
MAX_INPUT_LENGTH = 3 + 5 * MAX_N
MAX_OUTPUT_ELEMENTS = 3 * MAX_N


def expected_output(values: Sequence[int | float], capacity: int = MAX_OUTPUT_ELEMENTS,
                    output_is_null: bool = False, input_is_null: bool = False,
                    input_length: int | None = None) -> tuple[int, tuple[float, ...]]:
    if input_is_null or not isinstance(values, (list, tuple)):
        return -1, ()
    length = len(values) if input_length is None else input_length
    if (type(length) is not int or length != len(values)
            or length < 3 + 5*MIN_N or length > MAX_INPUT_LENGTH):
        return -1, ()
    if any(type(value) not in (int, float) or not math.isfinite(float(value))
           for value in values):
        return -1, ()
    n_raw, passes_raw, scalar = (float(values[i]) for i in range(3))
    if (n_raw != math.trunc(n_raw) or not MIN_N <= n_raw <= MAX_N
            or passes_raw != math.trunc(passes_raw) or not 1 <= passes_raw <= MAX_PASSES
            or scalar != math.trunc(scalar) or abs(scalar) > 1):
        return -1, ()
    n, passes = int(n_raw), int(passes_raw)
    if length != 3 + 5*n:
        return -1, ()
    if any(float(value) != math.trunc(float(value)) or abs(float(value)) > 1
           for value in values[3:]):
        return -1, ()
    if type(capacity) is not int or capacity < 0:
        return -1, ()
    if output_is_null or capacity < 3*n:
        return -2, ()
    data = [float(value) for value in values[3:]]
    a = data[0:n]
    b = data[n:2*n]
    c = data[2*n:3*n]
    d = data[3*n:4*n]
    e = data[4*n:5*n]
    for _ in range(passes):
        for i in range(n):
            if a[i] > b[i]:
                a[i] += b[i] * d[i]
                c[i] += d[i] * d[i]
            else:
                b[i] = a[i] + e[i] * e[i]
                if scalar > 0:
                    c[i] = a[i] + d[i] * d[i]
                else:
                    c[i] += e[i] * e[i]
    return 3*n, tuple(a + b + c)
