"""Oracle for the deterministic Julia independent-draw integration workload."""
from __future__ import annotations

import math
from collections.abc import Sequence

INVALID_RESULT = -1.0e300
SCALE = 1_000_000
MIN_SAMPLES = 1
MAX_SAMPLES = 16
MIN_BOUND = -10_000_000
MAX_BOUND = 10_000_000
MIN_UNIFORM = 0
MAX_UNIFORM = 999_999
MAX_VALID_INPUT_LENGTH = 19
MAX_PARSEABLE_INPUT_LENGTH = 20
ABSOLUTE_TOLERANCE = 1e-12
RELATIVE_TOLERANCE = 1e-12


def expected_result(values: Sequence[int] | None) -> float:
    if (not isinstance(values, (list, tuple))
            or not 3 <= len(values) <= MAX_PARSEABLE_INPUT_LENGTH
            or any(type(value) is not int or not -(2**63) <= value < 2**63
                   for value in values)):
        return INVALID_RESULT

    a_raw, b_raw, n = values[:3]
    if not MIN_SAMPLES <= n <= MAX_SAMPLES or len(values) != 3 + n:
        return INVALID_RESULT
    if (not MIN_BOUND <= a_raw <= MAX_BOUND
            or not MIN_BOUND <= b_raw <= MAX_BOUND
            or a_raw >= b_raw):
        return INVALID_RESULT
    draws = values[3:]
    if any(not MIN_UNIFORM <= draw <= MAX_UNIFORM for draw in draws):
        return INVALID_RESULT

    a = a_raw / SCALE
    b = b_raw / SCALE
    interval = b - a
    delta = interval / n
    total = 0.0
    for raw_draw in draws:
        u = raw_draw / SCALE
        x = a + interval * u
        total += x * x
    result = delta * total
    return result if math.isfinite(result) else INVALID_RESULT
