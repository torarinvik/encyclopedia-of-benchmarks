"""Independent exhaustive-subset oracle for the maximum-ratio workload."""

from __future__ import annotations

from collections.abc import Sequence
from itertools import combinations
from math import gcd

INVALID_RESULT = -1
MAX_ITEMS = 12
MAX_COMPONENT = 10_000
MAX_VALID_INPUT_LENGTH = 2 + 2 * MAX_ITEMS
MAX_PARSEABLE_INPUT_LENGTH = MAX_VALID_INPUT_LENGTH + 1
RATIO_BASE = MAX_ITEMS * MAX_COMPONENT + 1


def expected_result(values: Sequence[int] | None, input_is_null: bool = False,
                    input_length: int | None = None) -> int:
    if type(input_is_null) is not bool or input_is_null or not isinstance(values, (list, tuple)):
        return INVALID_RESULT
    length = len(values) if input_length is None else input_length
    if (type(length) is not int or length < 2 or length > MAX_PARSEABLE_INPUT_LENGTH
            or length != len(values)):
        return INVALID_RESULT
    if any(type(value) is not int or not -(1 << 63) <= value < (1 << 63) for value in values):
        return INVALID_RESULT
    item_count, cardinality = values[:2]
    if not 1 <= item_count <= MAX_ITEMS or not 1 <= cardinality <= item_count:
        return INVALID_RESULT
    if length != 2 + 2 * item_count:
        return INVALID_RESULT
    items = []
    for offset in range(2, length, 2):
        numerator, denominator = values[offset:offset + 2]
        if not 0 <= numerator <= MAX_COMPONENT or not 1 <= denominator <= MAX_COMPONENT:
            return INVALID_RESULT
        items.append((numerator, denominator))

    best_numerator = 0
    best_denominator = 1
    for selected in combinations(items, cardinality):
        numerator = sum(item[0] for item in selected)
        denominator = sum(item[1] for item in selected)
        if numerator * best_denominator > best_numerator * denominator:
            best_numerator, best_denominator = numerator, denominator
    divisor = gcd(best_numerator, best_denominator)
    return (best_numerator // divisor) * RATIO_BASE + best_denominator // divisor
