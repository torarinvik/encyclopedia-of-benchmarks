"""Grow-Expansion reference for exact summation of bounded dyadic inputs."""

from __future__ import annotations

from collections.abc import Sequence

MIN_TERMS = 0
MAX_TERMS = 16
MAX_VALID_INPUT_LENGTH = 33
MAX_PARSEABLE_INPUT_LENGTH = 34
MAX_LENGTH = MAX_PARSEABLE_INPUT_LENGTH
MAX_MANTISSA = 1 << 24
MIN_EXPONENT = -30
MAX_EXPONENT = 0
SCALE = 1 << 30
OUTPUT_OFFSET = (1 << 58) + 1
INVALID_RESULT = -1


def _parse(values: Sequence[int] | None, input_is_null: bool,
           input_length: int | None) -> tuple[tuple[int, int], ...] | None:
    if (type(input_is_null) is not bool or input_is_null
            or not isinstance(values, (list, tuple))
            or not 1 <= len(values) <= MAX_LENGTH
            or any(type(word) is not int or not -(1 << 63) <= word < (1 << 63)
                   for word in values)):
        return None
    if input_length is None:
        input_length = len(values)
    if type(input_length) is not int or input_length != len(values):
        return None
    count = values[0]
    if not MIN_TERMS <= count <= MAX_TERMS or input_length != 1 + 2 * count:
        return None
    terms: list[tuple[int, int]] = []
    for i in range(count):
        mantissa, exponent = values[1 + 2 * i:3 + 2 * i]
        if not -MAX_MANTISSA <= mantissa <= MAX_MANTISSA:
            return None
        if not MIN_EXPONENT <= exponent <= MAX_EXPONENT:
            return None
        terms.append((mantissa, exponent))
    return tuple(terms)


def _two_sum(a: float, b: float) -> tuple[float, float]:
    """Return rounded high part and exact residual under binary64 round-to-nearest."""
    high = a + b
    b_virtual = high - a
    a_virtual = high - b_virtual
    b_roundoff = b - b_virtual
    a_roundoff = a - a_virtual
    return high, a_roundoff + b_roundoff


def _grow_expansion(expansion: list[float], value: float) -> list[float]:
    """Add one scalar to a low-to-high nonoverlapping expansion."""
    q = value
    grown: list[float] = []
    for component in expansion:
        q, error = _two_sum(q, component)
        if error != 0.0:
            grown.append(error)
    if q != 0.0 or not grown:
        grown.append(q)
    return grown


def expected_result(values: Sequence[int] | None, input_is_null: bool = False,
                    input_length: int | None = None) -> int:
    terms = _parse(values, input_is_null, input_length)
    if terms is None:
        return INVALID_RESULT
    expansion: list[float] = []
    for mantissa, exponent in terms:
        value = float(mantissa)
        for _ in range(-exponent):
            value *= 0.5
        if value != 0.0:
            expansion = _grow_expansion(expansion, value)
    # Every component is an exact multiple of 2^-30. Scaling by 2^30
    # exposes the exact sum as a bounded integer without a final rounding.
    return OUTPUT_OFFSET + sum(int(component * SCALE) for component in expansion)
