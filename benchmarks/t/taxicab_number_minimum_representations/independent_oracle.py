"""Materialized pair-sum enumeration, independent of the row heap merge."""

from __future__ import annotations

MAX_ROOT = 444
MAX_VALID_INPUT_LENGTH = 1
MAX_PARSEABLE_INPUT_LENGTH = 2


def taxicab_number_minimum_representations_independent(
        values: list[int] | tuple[int, ...] | None,
        input_is_null: bool = False,
        input_length: int | None = None) -> int:
    if (type(input_is_null) is not bool or input_is_null
            or not isinstance(values, (list, tuple))
            or input_length is not None
            and (type(input_length) is not int or input_length != len(values))
            or len(values) != MAX_VALID_INPUT_LENGTH):
        return -1
    ways = values[0]
    if type(ways) is not int or not -(1 << 63) <= ways < (1 << 63) or ways not in (2, 3):
        return -1

    sums = [
        a * a * a + b * b * b
        for a in range(1, MAX_ROOT + 1)
        for b in range(a, MAX_ROOT + 1)
    ]
    sums.sort()
    index = 0
    while index < len(sums):
        end = index + 1
        while end < len(sums) and sums[end] == sums[index]:
            end += 1
        if end - index >= ways:
            return sums[index]
        index = end
    return -1
