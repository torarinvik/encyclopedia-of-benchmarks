"""Oracle for the exact-log bounded comparison in the pinned large-power example."""

from __future__ import annotations

MAX_BASE = 1_000_000_000_000
MAX_EXPONENT = 1_000_000_000_000
MAX_INPUT_LENGTH = 4
INVALID_RESULT = -2


def _decimal_exponent(base: int) -> int | None:
    """Return k for base == 10**k, or None when base is not a supported power."""
    if not 1 <= base <= MAX_BASE:
        return None
    exponent = 0
    while base > 1 and base % 10 == 0:
        base //= 10
        exponent += 1
    return exponent if base == 1 else None


def _source_score(base: int, exponent: int) -> int:
    """Preserve source branch order and normalize log10(10**k) to exact k."""
    if base == 0:
        return 0
    if exponent == 0:
        return 1
    decimal_exponent = _decimal_exponent(base)
    if decimal_exponent is None:
        raise AssertionError("base must be a supported decimal power")
    return decimal_exponent * exponent


def expected_result(values: list[int]) -> int:
    if (not isinstance(values, list) or len(values) != MAX_INPUT_LENGTH
            or any(type(value) is not int or not -(1 << 63) <= value < (1 << 63) for value in values)):
        return INVALID_RESULT
    base_a, exponent_a, base_b, exponent_b = values
    if (not 0 <= base_a <= MAX_BASE or not 0 <= base_b <= MAX_BASE
            or not 0 <= exponent_a <= MAX_EXPONENT or not 0 <= exponent_b <= MAX_EXPONENT):
        return INVALID_RESULT
    if (base_a != 0 and _decimal_exponent(base_a) is None
            or base_b != 0 and _decimal_exponent(base_b) is None):
        return INVALID_RESULT
    score_a = _source_score(base_a, exponent_a)
    score_b = _source_score(base_b, exponent_b)
    return (score_a > score_b) - (score_a < score_b)
