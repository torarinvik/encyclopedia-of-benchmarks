"""Brute-force y search for small fundamental Pell solutions."""

from __future__ import annotations

from math import isqrt

from .primary_oracle import (
    I64_MAX,
    I64_MIN,
    MAX_D,
    MAX_PARSEABLE_INPUT_LENGTH,
    MIN_D,
    PACK_SHIFT,
)

MAX_Y_SEARCH = 4096


def _decode(values, input_is_null: bool, input_length: int | None):
    if (type(input_is_null) is not bool or input_is_null
            or not isinstance(values, (tuple, list))
            or len(values) > MAX_PARSEABLE_INPUT_LENGTH
            or any(type(value) is not int or not I64_MIN <= value <= I64_MAX
                   for value in values)):
        return None
    if input_length is not None and (
            type(input_length) is not int or input_length != len(values)):
        return None
    if len(values) != 1 or not MIN_D <= values[0] <= MAX_D:
        return None
    d = values[0]
    root = isqrt(d)
    if root * root == d:
        return None
    return d


def expected_result(values, input_is_null: bool = False,
                    input_length: int | None = None) -> int:
    d = _decode(values, input_is_null, input_length)
    if d is None:
        return -1
    for y in range(1, MAX_Y_SEARCH + 1):
        x = isqrt(d * y * y + 1)
        if x * x == d * y * y + 1:
            return (x << PACK_SHIFT) | y
    return -1
