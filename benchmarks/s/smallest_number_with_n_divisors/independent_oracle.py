"""Independent divisor-count sieve for the bounded inverse-divisor task."""

from __future__ import annotations

from array import array
from functools import lru_cache

from .primary_oracle import (
    I64_MAX, I64_MIN, MAX_DIVISOR_COUNT, MAX_LIMIT,
    MAX_PARSEABLE_INPUT_LENGTH,
)


@lru_cache(maxsize=16)
def _counts_through(limit: int) -> array:
    counts = array("I", [0]) * (limit + 1)
    for divisor in range(1, limit + 1):
        for multiple in range(divisor, limit + 1, divisor):
            counts[multiple] += 1
    return counts


def expected_result(values, input_is_null: bool = False,
                    input_length: int | None = None) -> int:
    if (type(input_is_null) is not bool or input_is_null
            or not isinstance(values, (tuple, list))
            or len(values) > MAX_PARSEABLE_INPUT_LENGTH
            or any(type(value) is not int or not I64_MIN <= value <= I64_MAX
                   for value in values)):
        return -1
    if input_length is not None and (
            type(input_length) is not int or input_length != len(values)):
        return -1
    if len(values) != 2:
        return -1
    divisor_count, limit = values
    if not 1 <= divisor_count <= MAX_DIVISOR_COUNT or not 1 <= limit <= MAX_LIMIT:
        return -1
    counts = _counts_through(limit)
    for number in range(1, limit + 1):
        if counts[number] == divisor_count:
            return number
    return 0
