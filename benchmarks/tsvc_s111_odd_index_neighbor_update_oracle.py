"""Independent oracle for TSVC s111's odd-index neighbor update."""

from __future__ import annotations

import math
from collections.abc import Sequence

MAX_N = 64
MAX_VALUE = 1000
MAX_INPUT_LENGTH = 1 + 2 * MAX_N
MAX_OUTPUT_ELEMENTS = MAX_N
INVALID_RESULT = -1
OUTPUT_ERROR = -2


def expected_output(values: Sequence[int | float], capacity: int = MAX_OUTPUT_ELEMENTS,
                    output_is_null: bool = False, input_is_null: bool = False,
                    input_length: int | None = None) -> tuple[int, tuple[float, ...]]:
    if input_is_null or not isinstance(values, (list, tuple)):
        return INVALID_RESULT, ()
    length = len(values) if input_length is None else input_length
    if type(length) is not int or length != len(values) or not 3 <= length <= MAX_INPUT_LENGTH:
        return INVALID_RESULT, ()
    if any(type(x) not in (int, float) or not math.isfinite(float(x)) for x in values):
        return INVALID_RESULT, ()
    raw_n = float(values[0])
    if raw_n != math.trunc(raw_n) or not 1 <= raw_n <= MAX_N:
        return INVALID_RESULT, ()
    n = int(raw_n)
    if length != 1 + 2 * n:
        return INVALID_RESULT, ()
    data = values[1:]
    if any(float(x) != math.trunc(float(x)) or abs(float(x)) > MAX_VALUE for x in data):
        return INVALID_RESULT, ()
    if type(capacity) is not int or capacity < 0:
        return INVALID_RESULT, ()
    if output_is_null or capacity < n:
        return OUTPUT_ERROR, ()
    a = [float(x) for x in data[:n]]
    b = data[n:]
    for i in range(1, n, 2):
        a[i] = a[i - 1] + float(b[i])
    return n, tuple(a)
