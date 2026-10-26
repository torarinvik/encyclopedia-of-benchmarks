"""Independent oracle for the bounded TSVC s222 interleaved update."""

from __future__ import annotations

import math
from collections.abc import Sequence

MAX_N = 64
MAX_INPUT_LENGTH = 1 + 4 * MAX_N
MAX_OUTPUT_ELEMENTS = 2 * MAX_N
INVALID_RESULT = -1
OUTPUT_ERROR = -2
SEEDS = {-1.0, -0.5, 0.0, 0.5, 1.0}


def expected_output(values: Sequence[int | float], capacity: int | None = None,
                    output_is_null: bool = False, input_is_null: bool = False,
                    input_length: int | None = None) -> tuple[int, tuple[float, ...]]:
    if (input_is_null or not isinstance(values, (list, tuple))
            or input_length is not None and input_length != len(values)
            or len(values) < 5 or len(values) > MAX_INPUT_LENGTH):
        return INVALID_RESULT, ()
    if any(type(value) not in (int, float) or not math.isfinite(float(value))
           for value in values):
        return INVALID_RESULT, ()
    rn = float(values[0])
    if not rn.is_integer() or not 1 <= rn <= MAX_N:
        return INVALID_RESULT, ()
    n = int(rn)
    if len(values) != 1 + 4 * n:
        return INVALID_RESULT, ()
    a = [float(value) for value in values[1:1+n]]
    b = [float(value) for value in values[1+n:1+2*n]]
    c = [float(value) for value in values[1+2*n:1+3*n]]
    e = [float(value) for value in values[1+3*n:]]
    if (any(not value.is_integer() or abs(value) > 2 for value in a+b+c)
            or any(value not in SEEDS for value in e)):
        return INVALID_RESULT, ()
    if capacity is not None and (type(capacity) is not int or capacity < 0):
        return INVALID_RESULT, ()
    required = 2 * n
    if output_is_null or (capacity is not None and capacity < required):
        return OUTPUT_ERROR, ()
    for i in range(1, n):
        product = b[i] * c[i]
        a[i] = a[i] + product
        e[i] = e[i - 1] * e[i - 1]
        a[i] = a[i] - product
    return required, tuple(a + e)
