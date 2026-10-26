"""Independent oracle for TSVC s275's guarded column recurrence."""

from __future__ import annotations

import math
from collections.abc import Sequence

MAX_N = 8
MAX_VALUE = 16
MAX_INPUT_LENGTH = 1 + 3 * MAX_N * MAX_N
MAX_OUTPUT_ELEMENTS = MAX_N * MAX_N
INVALID_RESULT = -1
OUTPUT_ERROR = -2


def expected_output(values: Sequence[int | float], capacity: int = MAX_OUTPUT_ELEMENTS,
                    output_is_null: bool = False, input_is_null: bool = False,
                    input_length: int | None = None) -> tuple[int, tuple[float, ...]]:
    if input_is_null or not isinstance(values, (list, tuple)):
        return INVALID_RESULT, ()
    length = len(values) if input_length is None else input_length
    if type(length) is not int or length != len(values) or not 2 <= length <= MAX_INPUT_LENGTH:
        return INVALID_RESULT, ()
    if any(type(x) not in (int, float) or not math.isfinite(float(x)) for x in values):
        return INVALID_RESULT, ()
    raw_n = float(values[0])
    if raw_n != math.trunc(raw_n) or not 1 <= raw_n <= MAX_N:
        return INVALID_RESULT, ()
    n = int(raw_n)
    if length != 1 + 3 * n * n:
        return INVALID_RESULT, ()
    data = values[1:]
    if any(float(x) != math.trunc(float(x)) or abs(float(x)) > MAX_VALUE for x in data):
        return INVALID_RESULT, ()
    if type(capacity) is not int or capacity < 0:
        return INVALID_RESULT, ()
    if output_is_null or capacity < n * n:
        return OUTPUT_ERROR, ()
    a = [float(x) for x in data[:n * n]]
    b = data[n * n:2 * n * n]
    c = data[2 * n * n:]
    for col in range(n):
        if a[col] > 0.0:
            for row in range(1, n):
                index = row * n + col
                a[index] = a[index - n] + float(b[index]) * float(c[index])
    return n * n, tuple(a)
