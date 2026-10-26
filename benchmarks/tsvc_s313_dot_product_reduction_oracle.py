"""Independent oracle for the bounded TSVC s313 dot-product reduction."""

from __future__ import annotations

import math
from collections.abc import Sequence

MAX_N = 64
MAX_VALUE = 1000
MAX_INPUT_LENGTH = 1 + 2 * MAX_N
MAX_OUTPUT_ELEMENTS = 1
INVALID_RESULT = -1
OUTPUT_ERROR = -2


def expected_output(values: Sequence[int | float], capacity: int = 1,
                    output_is_null: bool = False, input_is_null: bool = False,
                    input_length: int | None = None) -> tuple[int, tuple[float, ...]]:
    if input_is_null or not isinstance(values, (list, tuple)):
        return INVALID_RESULT, ()
    length = len(values) if input_length is None else input_length
    if type(length) is not int or length != len(values) or not 3 <= length <= MAX_INPUT_LENGTH:
        return INVALID_RESULT, ()
    if any(type(x) not in (int, float) or not math.isfinite(float(x)) for x in values):
        return INVALID_RESULT, ()
    n_raw = float(values[0])
    if n_raw != math.trunc(n_raw) or not 1 <= n_raw <= MAX_N or length != 1 + 2 * int(n_raw):
        return INVALID_RESULT, ()
    n = int(n_raw)
    data = values[1:]
    if any(float(x) != math.trunc(float(x)) or abs(float(x)) > MAX_VALUE for x in data):
        return INVALID_RESULT, ()
    if type(capacity) is not int or capacity < 0:
        return INVALID_RESULT, ()
    if output_is_null or capacity < MAX_OUTPUT_ELEMENTS:
        return OUTPUT_ERROR, ()
    a = data[:n]
    b = data[n:]
    total = 0.0
    for i in range(n):
        total += float(a[i]) * float(b[i])
    return 1, (total,)
