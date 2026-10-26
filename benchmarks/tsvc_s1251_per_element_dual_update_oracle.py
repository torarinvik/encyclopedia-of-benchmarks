"""Independent oracle for TSVC Expansion s1251."""
from __future__ import annotations

import math
from collections.abc import Sequence

MAX_N = 64
MAX_INPUT_LENGTH = 1 + 5 * MAX_N
MAX_OUTPUT_ELEMENTS = 2 * MAX_N
INVALID_RESULT = -1
OUTPUT_ERROR = -2


def expected_output(values: Sequence[int | float], capacity: int = MAX_OUTPUT_ELEMENTS,
                    output_is_null: bool = False, input_is_null: bool = False,
                    input_length: int | None = None) -> tuple[int, tuple[float, ...]]:
    if input_is_null or not isinstance(values, (list, tuple)):
        return INVALID_RESULT, ()
    length = len(values) if input_length is None else input_length
    if type(length) is not int or length != len(values) or not 6 <= length <= MAX_INPUT_LENGTH:
        return INVALID_RESULT, ()
    if any(type(value) not in (int, float) or not math.isfinite(float(value))
           for value in values):
        return INVALID_RESULT, ()
    raw_n = float(values[0])
    if raw_n != math.trunc(raw_n) or not 1 <= raw_n <= MAX_N:
        return INVALID_RESULT, ()
    n = int(raw_n)
    if length != 1 + 5 * n:
        return INVALID_RESULT, ()
    if any(float(value) != math.trunc(float(value)) or abs(float(value)) > 1
           for value in values[1:]):
        return INVALID_RESULT, ()
    if type(capacity) is not int or capacity < 0:
        return INVALID_RESULT, ()
    if output_is_null or capacity < 2 * n:
        return OUTPUT_ERROR, ()
    a = [float(value) for value in values[1:1+n]]
    b = [float(value) for value in values[1+n:1+2*n]]
    c = values[1+2*n:1+3*n]
    d = values[1+3*n:1+4*n]
    e = values[1+4*n:1+5*n]
    for i in range(n):
        saved_sum = b[i] + float(c[i])
        new_b = a[i] + float(d[i])
        new_a = saved_sum * float(e[i])
        b[i] = new_b
        a[i] = new_a
    return 2 * n, tuple(a + b)
