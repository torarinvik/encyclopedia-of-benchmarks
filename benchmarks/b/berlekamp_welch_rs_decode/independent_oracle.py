"""Exhaustive coefficient enumeration for bounded GF(7) Reed-Solomon decoding."""

from __future__ import annotations

from collections.abc import Sequence
from itertools import product

FIELD = 7


def expected_result(values: Sequence[int] | None, input_is_null: bool = False,
                    input_length: int | None = None) -> int:
    if (type(input_is_null) is not bool or input_is_null
            or not isinstance(values, (list, tuple)) or len(values) < 3
            or len(values) > 11
            or any(type(value) is not int or not -(1 << 63) <= value < (1 << 63)
                   for value in values)):
        return -1
    if input_length is not None and (
            type(input_length) is not int or input_length != len(values)):
        return -1
    n, k, errors = values[:3]
    if (not 2 <= n <= 7 or not 1 <= k <= min(3, n)
            or not 0 <= errors <= 2 or 2 * errors > n - k
            or len(values) != 3 + n
            or any(not 0 <= symbol < FIELD for symbol in values[3:])):
        return -1

    received = values[3:]
    candidate: tuple[int, ...] | None = None
    for coefficients in product(range(FIELD), repeat=k):
        mismatches = 0
        for x, symbol in enumerate(received):
            value = 0
            for coefficient in reversed(coefficients):
                value = (value * x + coefficient) % FIELD
            mismatches += value != symbol
        if mismatches <= errors:
            if candidate is not None:
                # The promise 2t < d guarantees uniqueness; guard the reference.
                return -1
            candidate = coefficients
    if candidate is None:
        return 0
    return 1 + sum(coefficient * FIELD**i
                   for i, coefficient in enumerate(candidate))
