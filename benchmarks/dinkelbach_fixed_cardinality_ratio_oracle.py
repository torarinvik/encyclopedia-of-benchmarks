"""Dinkelbach iteration for exact fixed-cardinality maximum-ratio selection."""

from __future__ import annotations

from collections.abc import Sequence
from math import comb, gcd

MAX_ITEMS = 12
MAX_CARDINALITY = 12
MAX_COMPONENT = 10_000
MAX_SUM = MAX_ITEMS * MAX_COMPONENT
RATIO_BASE = MAX_SUM + 1
MAX_VALID_INPUT_LENGTH = 2 + 2 * MAX_ITEMS
MAX_PARSEABLE_INPUT_LENGTH = MAX_VALID_INPUT_LENGTH + 1
INVALID_RESULT = -1


def _parse(values: Sequence[int] | None, input_is_null: bool,
           input_length: int | None) -> tuple[int, int, list[tuple[int, int]]] | None:
    if type(input_is_null) is not bool or input_is_null or not isinstance(values, (list, tuple)):
        return None
    length = len(values) if input_length is None else input_length
    if (type(length) is not int or length < 2 or length > MAX_PARSEABLE_INPUT_LENGTH
            or length != len(values)):
        return None
    if any(type(value) is not int or not -(1 << 63) <= value < (1 << 63) for value in values):
        return None
    item_count, cardinality = values[:2]
    if not 1 <= item_count <= MAX_ITEMS or not 1 <= cardinality <= item_count:
        return None
    if length != 2 + 2 * item_count:
        return None
    items: list[tuple[int, int]] = []
    for offset in range(2, length, 2):
        numerator, denominator = values[offset:offset + 2]
        if not 0 <= numerator <= MAX_COMPONENT or not 1 <= denominator <= MAX_COMPONENT:
            return None
        items.append((numerator, denominator))
    return item_count, cardinality, items


def _encode_ratio(numerator: int, denominator: int) -> int:
    divisor = gcd(numerator, denominator)
    reduced_numerator = numerator // divisor
    reduced_denominator = denominator // divisor
    return reduced_numerator * RATIO_BASE + reduced_denominator


def expected_result(values: Sequence[int] | None, input_is_null: bool = False,
                    input_length: int | None = None) -> int:
    parsed = _parse(values, input_is_null, input_length)
    if parsed is None:
        return INVALID_RESULT
    item_count, cardinality, items = parsed
    numerator = 0
    denominator = 1

    # Every positive Dinkelbach step selects a new cardinality-K subset with a
    # strictly larger ratio, so this finite bound exceeds the number of subsets.
    for _ in range(comb(item_count, cardinality) + 1):
        order = sorted(
            range(item_count),
            key=lambda index: (
                -(items[index][0] * denominator - numerator * items[index][1]),
                index,
            ),
        )
        selected = order[:cardinality]
        next_numerator = sum(items[index][0] for index in selected)
        next_denominator = sum(items[index][1] for index in selected)
        residual = next_numerator * denominator - numerator * next_denominator
        if residual == 0:
            return _encode_ratio(next_numerator, next_denominator)
        if residual < 0:
            return INVALID_RESULT
        divisor = gcd(next_numerator, next_denominator)
        numerator = next_numerator // divisor
        denominator = next_denominator // divisor
    return INVALID_RESULT
