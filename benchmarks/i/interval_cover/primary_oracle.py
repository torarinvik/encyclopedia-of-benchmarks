"""Greedy minimum interval cover for a bounded half-open target."""

from __future__ import annotations

from collections.abc import Sequence

MAX_INTERVALS = 16
MAX_COORDINATE = 32
MAX_VALID_INPUT_LENGTH = 3 + 2 * MAX_INTERVALS
MAX_PARSEABLE_INPUT_LENGTH = MAX_VALID_INPUT_LENGTH + 1
INVALID_RESULT = -2
IMPOSSIBLE_RESULT = -1


def _decode(values: Sequence[int] | None, input_is_null: bool,
            input_length: int | None) -> tuple[int, int, list[tuple[int, int]]] | None:
    if (type(input_is_null) is not bool or input_is_null
            or not isinstance(values, (list, tuple))
            or len(values) < 3 or len(values) > MAX_PARSEABLE_INPUT_LENGTH
            or any(type(value) is not int or not -(1 << 63) <= value < (1 << 63)
                   for value in values)):
        return None
    if input_length is not None and (
            type(input_length) is not int or input_length != len(values)):
        return None

    left, right, count = values[:3]
    if not 0 <= left <= right <= MAX_COORDINATE:
        return None
    if not 0 <= count <= MAX_INTERVALS or len(values) != 3 + 2 * count:
        return None
    intervals: list[tuple[int, int]] = []
    for index in range(count):
        start, end = values[3 + 2 * index:5 + 2 * index]
        if not 0 <= start < end <= MAX_COORDINATE:
            return None
        intervals.append((start, end))
    return left, right, intervals


def expected_result(values: Sequence[int] | None, input_is_null: bool = False,
                    input_length: int | None = None) -> int:
    decoded = _decode(values, input_is_null, input_length)
    if decoded is None:
        return INVALID_RESULT
    target_left, target_right, intervals = decoded
    if target_left == target_right:
        return 0

    frontier = target_left
    selected = 0
    while frontier < target_right:
        farthest = frontier
        for start, end in intervals:
            if start <= frontier and end > farthest:
                farthest = end
        if farthest == frontier:
            return IMPOSSIBLE_RESULT
        frontier = farthest
        selected += 1
    return selected
