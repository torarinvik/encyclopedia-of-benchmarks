"""Visited-mask depth-first count for the bounded Android 3x3 rule set."""

from __future__ import annotations

from collections.abc import Sequence

MIN_PATTERN_LENGTH = 4
MAX_PATTERN_LENGTH = 9
MAX_VALID_INPUT_LENGTH = 1
MAX_PARSEABLE_INPUT_LENGTH = 2
MAX_RESULT = 140704
INVALID_RESULT = -1


def _middle_point(first: int, second: int) -> int | None:
    if first == second:
        return None
    first_x, first_y = first % 3, first // 3
    second_x, second_y = second % 3, second // 3
    delta_x, delta_y = second_x - first_x, second_y - first_y
    if delta_x % 2 != 0 or delta_y % 2 != 0:
        return None
    middle_x = (first_x + second_x) // 2
    middle_y = (first_y + second_y) // 2
    middle = middle_y * 3 + middle_x
    return None if middle in (first, second) else middle


def _count_from(last: int, visited: int, used: int, target: int) -> int:
    if used == target:
        return 1
    count = 0
    for next_point in range(9):
        bit = 1 << next_point
        if visited & bit:
            continue
        middle = _middle_point(last, next_point)
        if middle is not None and not (visited & (1 << middle)):
            continue
        count += _count_from(next_point, visited | bit, used + 1, target)
    return count


def _parse(values: Sequence[int] | None, input_is_null: bool,
           input_length: int | None) -> int | None:
    if (type(input_is_null) is not bool or input_is_null
            or not isinstance(values, (list, tuple))
            or not 1 <= len(values) <= MAX_PARSEABLE_INPUT_LENGTH
            or any(type(word) is not int or not -(1 << 63) <= word < (1 << 63)
                   for word in values)):
        return None
    if input_length is not None and (
            type(input_length) is not int or input_length != len(values)):
        return None
    if len(values) != 1 or not MIN_PATTERN_LENGTH <= values[0] <= MAX_PATTERN_LENGTH:
        return None
    return values[0]


def expected_result(values: Sequence[int] | None, input_is_null: bool = False,
                    input_length: int | None = None) -> int:
    target = _parse(values, input_is_null, input_length)
    if target is None:
        return INVALID_RESULT
    return sum(_count_from(start, 1 << start, 1, target) for start in range(9))
