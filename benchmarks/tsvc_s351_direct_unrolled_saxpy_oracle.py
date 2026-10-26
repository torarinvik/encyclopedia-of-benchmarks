"""Independent oracle for TSVC LoopRerolling s351."""
from __future__ import annotations

import math
from collections.abc import Sequence

MAX_N = 40
MAX_INPUT_LENGTH = 2 + 2 * MAX_N
MAX_OUTPUT_ELEMENTS = MAX_N
INVALID_RESULT = -1
OUTPUT_ERROR = -2


def expected_output(values: Sequence[int | float], capacity: int = MAX_N,
                    output_is_null: bool = False, input_is_null: bool = False,
                    input_length: int | None = None) -> tuple[int, tuple[float, ...]]:
    if input_is_null or not isinstance(values, (list, tuple)):
        return INVALID_RESULT, ()
    length = len(values) if input_length is None else input_length
    if type(length) is not int or length != len(values) or not 12 <= length <= MAX_INPUT_LENGTH:
        return INVALID_RESULT, ()
    if any(type(value) not in (int, float) or not math.isfinite(float(value))
           for value in values):
        return INVALID_RESULT, ()
    raw_n = float(values[0])
    if raw_n != math.trunc(raw_n) or not 5 <= raw_n <= MAX_N or int(raw_n) % 5:
        return INVALID_RESULT, ()
    n = int(raw_n)
    if length != 2 + 2 * n:
        return INVALID_RESULT, ()
    if any(float(value) != math.trunc(float(value)) or abs(float(value)) > 1
           for value in values[1:]):
        return INVALID_RESULT, ()
    if type(capacity) is not int or capacity < 0:
        return INVALID_RESULT, ()
    if output_is_null or capacity < n:
        return OUTPUT_ERROR, ()
    alpha = float(values[1])
    a = [float(value) for value in values[2:2+n]]
    b = values[2+n:]
    for group in range(0, n, 5):
        for offset in range(5):
            i = group + offset
            product = alpha * float(b[i])
            a[i] = a[i] + product
    return n, tuple(a)
