"""Sorted-list reference for the WBLT ordered-multiset operation trace."""

from __future__ import annotations

from bisect import bisect_left, bisect_right, insort

from .primary_oracle import (
    I64_MAX, I64_MIN, MAX_OPERATIONS, MAX_PARSEABLE_INPUT_LENGTH,
    MAX_KEY, MIN_KEY, NO_KEY,
)


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
    if not values or not 0 <= values[0] <= MAX_OPERATIONS:
        return -1
    count = values[0]
    if len(values) != 1 + 2 * count:
        return -1

    multiset: list[int] = []
    checksum = 0
    for step in range(1, count + 1):
        operation, argument = values[2 * step - 1:2 * step + 1]
        if operation not in range(6):
            return -1
        if operation == 3:
            if not 0 <= argument < MAX_OPERATIONS:
                return -1
        elif not MIN_KEY <= argument <= MAX_KEY:
            return -1
        if operation == 0:
            insort(multiset, argument)
            continue
        if operation == 1:
            index = bisect_left(multiset, argument)
            if index < len(multiset) and multiset[index] == argument:
                multiset.pop(index)
            continue
        if operation == 2:
            answer = bisect_left(multiset, argument)
        elif operation == 3:
            answer = multiset[argument] if argument < len(multiset) else NO_KEY
        elif operation == 4:
            index = bisect_left(multiset, argument) - 1
            answer = multiset[index] if index >= 0 else NO_KEY
        else:
            index = bisect_right(multiset, argument)
            answer = multiset[index] if index < len(multiset) else NO_KEY
        checksum += step * (answer - NO_KEY)
    return checksum
