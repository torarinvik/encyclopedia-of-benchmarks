"""Binary64 reference for the bounded cosine fixed-point iteration."""

from __future__ import annotations

import math


def expected_result(initial_x: float, source_n: float) -> float:
    if (not math.isfinite(initial_x) or not math.isfinite(source_n)
            or not 0.0 <= initial_x <= 2.0
            or not 0.0 <= source_n <= 64.0
            or source_n != math.floor(source_n)):
        return -1.0

    value = initial_x
    for _ in range(int(source_n) + 1):
        value = (math.cos(value) + 2.0) / 2.0
    return value
