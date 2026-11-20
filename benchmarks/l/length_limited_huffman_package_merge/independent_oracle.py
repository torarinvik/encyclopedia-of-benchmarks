"""Independent bounded exhaustive oracle over feasible code-length vectors."""

from __future__ import annotations

from collections.abc import Sequence

MIN_SYMBOLS = 2
MAX_SYMBOLS = 12
MIN_LENGTH_LIMIT = 1
MAX_LENGTH_LIMIT = 6
MIN_WEIGHT = 0
MAX_WEIGHT = 1_000_000
MAX_INPUT_LENGTH = MAX_SYMBOLS + 3
MAX_RESULT = MAX_SYMBOLS * MAX_LENGTH_LIMIT * MAX_WEIGHT


def expected_result(values: Sequence[int] | None, input_is_null: bool = False,
                    input_length: int | None = None) -> int:
    if (type(input_is_null) is not bool or input_is_null
            or not isinstance(values, (list, tuple))
            or not MIN_SYMBOLS + 2 <= len(values) <= MAX_INPUT_LENGTH
            or any(type(value) is not int or not -(1 << 63) <= value < (1 << 63)
                   for value in values)
            or input_length is not None
            and (type(input_length) is not int or input_length != len(values))):
        return -1
    symbol_count, length_limit = values[:2]
    if (not MIN_SYMBOLS <= symbol_count <= MAX_SYMBOLS
            or not MIN_LENGTH_LIMIT <= length_limit <= MAX_LENGTH_LIMIT
            or symbol_count > 1 << length_limit
            or len(values) != symbol_count + 2
            or any(not MIN_WEIGHT <= weight <= MAX_WEIGHT for weight in values[2:])):
        return -1

    ordered_weights = sorted(values[2:], reverse=True)
    kraft_capacity = 1 << length_limit
    best = MAX_RESULT + 1

    def enumerate_lengths(index: int, previous_length: int,
                          kraft_units: int, cost: int) -> None:
        nonlocal best
        if index == symbol_count:
            if cost < best:
                best = cost
            return
        for length in range(previous_length, length_limit + 1):
            next_kraft = kraft_units + (1 << (length_limit - length))
            if next_kraft <= kraft_capacity:
                enumerate_lengths(index + 1, length, next_kraft,
                                  cost + ordered_weights[index] * length)

    enumerate_lengths(0, 1, 0, 0)
    return best if best <= MAX_RESULT else -1
