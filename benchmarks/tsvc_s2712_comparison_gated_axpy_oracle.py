"""Independent oracle for TSVC ControlFlow s2712."""
from __future__ import annotations

import math
from collections.abc import Sequence

MAX_N = 64
MAX_PASSES = 8
MAX_INPUT_LENGTH = 2 + 3 * MAX_N
MAX_OUTPUT_ELEMENTS = MAX_N


def expected_output(values: Sequence[int | float], capacity: int = MAX_OUTPUT_ELEMENTS,
                    output_is_null: bool = False, input_is_null: bool = False,
                    input_length: int | None = None) -> tuple[int, tuple[float, ...]]:
    if input_is_null or not isinstance(values, (list, tuple)):
        return -1, ()
    length = len(values) if input_length is None else input_length
    if type(length) is not int or length != len(values) or not 5 <= length <= MAX_INPUT_LENGTH:
        return -1, ()
    if any(type(value) not in (int, float) or not math.isfinite(float(value))
           for value in values):
        return -1, ()
    n_raw, passes_raw = float(values[0]), float(values[1])
    if (n_raw != math.trunc(n_raw) or not 1 <= n_raw <= MAX_N
            or passes_raw != math.trunc(passes_raw) or not 1 <= passes_raw <= MAX_PASSES):
        return -1, ()
    n, passes = int(n_raw), int(passes_raw)
    if length != 2 + 3*n:
        return -1, ()
    if any(float(value) != math.trunc(float(value)) or abs(float(value)) > 2
           for value in values[2:]):
        return -1, ()
    if type(capacity) is not int or capacity < 0:
        return -1, ()
    if output_is_null or capacity < n:
        return -2, ()
    a = [float(value) for value in values[2:2+n]]
    b = [float(value) for value in values[2+n:2+2*n]]
    c = [float(value) for value in values[2+2*n:]]
    for _ in range(passes):
        for i in range(n):
            if a[i] > b[i]:
                a[i] += b[i] * c[i]
    return n, tuple(a)
