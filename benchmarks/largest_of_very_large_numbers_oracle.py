"""Oracle for the bounded comparison in the pinned large-power example."""

from __future__ import annotations

import math

MAX_BASE = 1_000_000_000_000
MAX_EXPONENT = 1_000_000_000_000
MAX_INPUT_LENGTH = 4
INVALID_RESULT = -2


def _source_score(base: int, exponent: int) -> float:
    if base != 0 and exponent != 0:
        return exponent * math.log10(base)
    if base == 0:
        return 0.0
    if exponent == 0:
        return 1.0
    raise AssertionError("unreachable under the bounded nonnegative domain")


def expected_result(values: list[int]) -> int:
    if (not isinstance(values, list) or len(values) != MAX_INPUT_LENGTH
            or any(type(value) is not int or not -(1 << 63) <= value < (1 << 63) for value in values)):
        return INVALID_RESULT
    base_a, exponent_a, base_b, exponent_b = values
    if (not 0 <= base_a <= MAX_BASE or not 0 <= base_b <= MAX_BASE
            or not 0 <= exponent_a <= MAX_EXPONENT or not 0 <= exponent_b <= MAX_EXPONENT):
        return INVALID_RESULT
    if (exponent_a != exponent_b
            and (base_a != base_b
                 or (base_a != 0 and (exponent_a == 0) != (exponent_b == 0)))):
        return INVALID_RESULT
    score_a = _source_score(base_a, exponent_a)
    score_b = _source_score(base_b, exponent_b)
    return (score_a > score_b) - (score_a < score_b)
