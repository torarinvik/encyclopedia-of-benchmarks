"""Quadratic direct-suffix reference for aggregate sums and distinct counts."""

from __future__ import annotations

from collections.abc import Sequence
from math import gcd

from .primary_oracle import (
    INVALID_RESULT, MAX_N, MAX_PARSEABLE_INPUT_LENGTH, MAX_VALUE,
    PACKING_MULTIPLIER,
)


def _combine(mode: int, left: int, right: int) -> int:
    if mode == 0:
        return gcd(left, right)
    if mode == 1:
        return left | right
    return left & right


def _decode(values: Sequence[int] | None, input_is_null: bool,
            input_length: int | None) -> tuple[int, list[int]] | None:
    if (type(input_is_null) is not bool or input_is_null
            or not isinstance(values, (list, tuple))
            or not 2 <= len(values) <= MAX_PARSEABLE_INPUT_LENGTH
            or any(type(word) is not int or not -(1 << 63) <= word < (1 << 63)
                   for word in values)):
        return None
    if input_length is not None and (
            type(input_length) is not int or input_length != len(values)):
        return None
    mode, n = values[:2]
    if mode not in (0, 1, 2) or not 0 <= n <= MAX_N or len(values) != 2 + n:
        return None
    data = list(values[2:])
    if any(not 0 <= value <= MAX_VALUE for value in data):
        return None
    return mode, data


def expected_result(values: Sequence[int] | None, input_is_null: bool = False,
                    input_length: int | None = None) -> int:
    """Scan every subarray directly, with no suffix-range compression."""
    parsed = _decode(values, input_is_null, input_length)
    if parsed is None:
        return INVALID_RESULT
    mode, data = parsed
    aggregate_sum = 0
    suffix_distinct_count = 0
    for right in range(len(data)):
        ending_values: set[int] = set()
        aggregate = data[right]
        for left in range(right, -1, -1):
            if left != right:
                aggregate = _combine(mode, data[left], aggregate)
            aggregate_sum += aggregate
            ending_values.add(aggregate)
        suffix_distinct_count += len(ending_values)
    return aggregate_sum * PACKING_MULTIPLIER + suffix_distinct_count
