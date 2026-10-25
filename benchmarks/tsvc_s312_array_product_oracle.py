"""Independent oracle for the bounded TSVC s312 product reduction."""

from __future__ import annotations

from collections.abc import Sequence

MAX_N = 48
MAX_INPUT_LENGTH = 1 + MAX_N
MAX_VALUE = 2
I64_MIN = -(1 << 63)
I64_MAX = (1 << 63) - 1


def expected_result(values: Sequence[int] | None) -> int:
    """Return the product of the packed array, or -1 for invalid input."""
    if values is None or not isinstance(values, (list, tuple)):
        return -1
    if not 1 <= len(values) <= MAX_INPUT_LENGTH:
        return -1
    if any(type(value) is not int or not I64_MIN <= value <= I64_MAX for value in values):
        return -1
    n = values[0]
    if not 0 <= n <= MAX_N or len(values) != 1 + n:
        return -1
    factors = values[1:]
    if any(not 0 <= value <= MAX_VALUE for value in factors):
        return -1
    product = 1
    for factor in factors:
        product *= factor
    return product
