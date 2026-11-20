"""Sorted-list reference for the size-balanced ordered-set workload."""

from __future__ import annotations

from bisect import bisect_left, bisect_right

from .primary_oracle import (
    I64_MAX,
    I64_MIN,
    MAX_OPERATIONS,
    MAX_PARSEABLE_INPUT_LENGTH,
    MAX_KEY,
    MIN_KEY,
    NO_KEY,
)


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
    if not values or not 0 <= values[0] <= MAX_OPERATIONS:
        return None
    count = values[0]
    if len(values) != 1 + 2 * count:
        return None
    operations = []
    for index in range(count):
        operation, argument = values[1 + 2 * index:3 + 2 * index]
        if operation not in range(5):
            return None
        if operation == 2:
            if not 0 <= argument < MAX_OPERATIONS:
                return None
        elif not MIN_KEY <= argument <= MAX_KEY:
            return None
        operations.append((operation, argument))
    return operations


def expected_result(values, input_is_null: bool = False,
                    input_length: int | None = None) -> int:
    operations = _decode(values, input_is_null, input_length)
    if operations is None:
        return -1
    ordered: list[int] = []
    checksum = 0
    for step, (operation, argument) in enumerate(operations, start=1):
        position = bisect_left(ordered, argument)
        if operation == 0:
            if position == len(ordered) or ordered[position] != argument:
                ordered.insert(position, argument)
            continue
        if operation == 1:
            answer = position
        elif operation == 2:
            answer = ordered[argument] if argument < len(ordered) else NO_KEY
        elif operation == 3:
            answer = ordered[position - 1] if position else NO_KEY
        else:
            right = bisect_right(ordered, argument)
            answer = ordered[right] if right < len(ordered) else NO_KEY
        checksum += step * (answer - NO_KEY)
    return checksum
