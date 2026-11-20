"""Exact subset enumeration reference for the ratio-knapsack profile."""

from __future__ import annotations

from collections.abc import Sequence

MAX_N = 12
MAX_WEIGHT = 32
MAX_VALID_INPUT_LENGTH = 26
MAX_PARSEABLE_INPUT_LENGTH = 27
SCALE = 1_000_000
MAX_RESULT = 1_000_000_000
MAX_WORKSPACE_BYTES = 2_048
INVALID_RESULT = -1
I64_MIN, I64_MAX = -(1 << 63), (1 << 63) - 1


def expected_result(values: Sequence[int] | None, input_is_null: bool = False,
                    input_length: int | None = None) -> int:
    if (type(input_is_null) is not bool or input_is_null
            or not isinstance(values, (list, tuple))
            or not 1 <= len(values) <= MAX_PARSEABLE_INPUT_LENGTH
            or any(type(value) is not int or value < I64_MIN or value > I64_MAX
                   for value in values)):
        return INVALID_RESULT
    if input_length is not None and (
            type(input_length) is not int or input_length != len(values)):
        return INVALID_RESULT
    if len(values) < 2:
        return INVALID_RESULT
    n, required = values[0], values[1]
    if not 1 <= n <= MAX_N or not 1 <= required <= MAX_WEIGHT:
        return INVALID_RESULT
    if len(values) != 2 + 2 * n:
        return INVALID_RESULT
    items = [tuple(values[2 + 2 * i:4 + 2 * i]) for i in range(n)]
    if any(not 0 <= a <= 1000 or not 1 <= b <= 8 for a, b in items):
        return INVALID_RESULT
    if sum(b for _, b in items) < required:
        return INVALID_RESULT

    best_numerator = 0
    best_denominator = 1
    for subset in range(1, 1 << n):
        numerator_sum = 0
        denominator_sum = 0
        for item, (numerator, denominator) in enumerate(items):
            if subset & (1 << item):
                numerator_sum += numerator
                denominator_sum += denominator
        if denominator_sum >= required and (
                numerator_sum * best_denominator > best_numerator * denominator_sum):
            best_numerator = numerator_sum
            best_denominator = denominator_sum
    return (SCALE * best_numerator) // best_denominator
