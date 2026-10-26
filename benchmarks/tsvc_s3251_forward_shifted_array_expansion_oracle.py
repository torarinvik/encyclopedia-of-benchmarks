"""Independent oracle for TSVC Expansion s3251."""
from __future__ import annotations

import math
from collections.abc import Sequence

MAX_N = 64
MAX_INPUT_LENGTH = 1 + 5 * MAX_N
MAX_OUTPUT_ELEMENTS = 3 * MAX_N


def expected_output(values: Sequence[int | float], capacity: int = MAX_OUTPUT_ELEMENTS,
                    output_is_null: bool = False, input_is_null: bool = False,
                    input_length: int | None = None) -> tuple[int, tuple[float, ...]]:
    if input_is_null or not isinstance(values, (list, tuple)):
        return -1, ()
    length = len(values) if input_length is None else input_length
    if type(length) is not int or length != len(values) or not 6 <= length <= MAX_INPUT_LENGTH:
        return -1, ()
    if any(type(value) not in (int, float) or not math.isfinite(float(value))
           for value in values):
        return -1, ()
    raw_n = float(values[0])
    if raw_n != math.trunc(raw_n) or not 1 <= raw_n <= MAX_N:
        return -1, ()
    n = int(raw_n)
    if length != 1 + 5*n:
        return -1, ()
    if any(float(value) != math.trunc(float(value)) or abs(float(value)) > 1
           for value in values[1:]):
        return -1, ()
    if type(capacity) is not int or capacity < 0:
        return -1, ()
    if output_is_null or capacity < 3*n:
        return -2, ()
    data = [float(value) for value in values[1:]]
    a = data[0:n]
    b = data[n:2*n]
    c = data[2*n:3*n]
    d = data[3*n:4*n]
    e = data[4*n:5*n]
    for index in range(n - 1):
        a[index + 1] = b[index] + c[index]
        b[index] = c[index] * e[index]
        d[index] = a[index] * e[index]
    return 3*n, tuple(a + b + d)
