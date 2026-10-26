"""Independent bounded oracle for TSVC ControlFlow s441 and s443."""
from __future__ import annotations

import math
from collections.abc import Sequence

MAX_N = 64
MAX_PASSES = 8
MAX_INPUT_LENGTH = 3 + 4*MAX_N
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
    raw_mode, raw_n, raw_passes = (float(values[i]) for i in range(3))
    if (not raw_mode.is_integer() or raw_mode not in (0, 1)
            or not raw_n.is_integer() or not 1 <= raw_n <= MAX_N
            or not raw_passes.is_integer() or not 1 <= raw_passes <= MAX_PASSES):
        return -1, ()
    mode, n, passes = int(raw_mode), int(raw_n), int(raw_passes)
    if length != 3 + 4*n:
        return -1, ()
    body = [float(v) for v in values[3:]]
    if any(not v.is_integer() or abs(v) > 1 for v in body):
        return -1, ()
    if type(capacity) is not int or capacity < 0:
        return -1, ()
    if output_is_null or capacity < n:
        return -2, ()
    a = body[:n]
    b = body[n:2*n]
    c = body[2*n:3*n]
    d = body[3*n:4*n]
    for _ in range(passes):
        for i in range(n):
            if mode == 0:
                if d[i] < 0:
                    a[i] += b[i]*c[i]
                elif d[i] == 0:
                    a[i] += b[i]*b[i]
                else:
                    a[i] += c[i]*c[i]
            elif d[i] <= 0:
                a[i] += b[i]*c[i]
            else:
                a[i] += b[i]*b[i]
    return n, tuple(a)
