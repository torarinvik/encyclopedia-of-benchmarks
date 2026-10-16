"""Oracle for bounded fixed-step forward Euler integration of u'=v, v'=-u."""
from __future__ import annotations

import math
import struct

INVALID_RESULT = -1
INSUFFICIENT_CAPACITY_RESULT = -2
OUTPUT_BYTES = 16
MAX_INPUT_LENGTH = 5
EXACT_INPUT_LENGTH = 4


def expected_output(values: list[int] | tuple[int, ...]) -> tuple[int, bytes]:
    if (not isinstance(values, (list, tuple)) or len(values) != EXACT_INPUT_LENGTH
            or any(type(value) is not int for value in values)):
        return INVALID_RESULT, b""
    steps, dt_quarters, u0, v0 = values
    if not 1 <= steps <= 16 or not 1 <= dt_quarters <= 4 or not (-10 <= u0 <= 10) or not (-10 <= v0 <= 10):
        return INVALID_RESULT, b""
    dt = dt_quarters / 4.0
    u = float(u0)
    v = float(v0)
    for _ in range(steps):
        old_u, old_v = u, v
        u = old_u + dt * old_v
        v = old_v - dt * old_u
    if not math.isfinite(u) or not math.isfinite(v):
        return INVALID_RESULT, b""
    return OUTPUT_BYTES, struct.pack("<2d", u, v)
