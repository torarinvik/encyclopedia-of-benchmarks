"""Directly scan every current point for each online rectangle query."""

from __future__ import annotations

from collections.abc import Sequence

MAX_N = 24
MAX_Q = 32
WORDS_PER_OPERATION = 5
MAX_VALID_INPUT_LENGTH = 2 + MAX_N + WORDS_PER_OPERATION * MAX_Q
MAX_PARSEABLE_INPUT_LENGTH = MAX_VALID_INPUT_LENGTH + 1
INVALID_RESULT = -1


def _parse(values: Sequence[int] | None, input_is_null: bool,
           input_length: int | None) -> tuple[int, list[int], list[tuple[int, ...]]] | None:
    if (type(input_is_null) is not bool or input_is_null
            or not isinstance(values, (list, tuple))
            or len(values) < 2 or len(values) > MAX_PARSEABLE_INPUT_LENGTH
            or any(type(value) is not int or not -(1 << 63) <= value < (1 << 63)
                   for value in values)):
        return None
    if input_length is not None and (
            type(input_length) is not int or input_length != len(values)):
        return None
    n, q = values[0], values[1]
    if not 1 <= n <= MAX_N or not 1 <= q <= MAX_Q:
        return None
    expected_length = 2 + n + 5 * q
    if len(values) != expected_length:
        return None
    points = list(values[2:2 + n])
    if any(y < 0 or y >= n for y in points):
        return None
    operations: list[tuple[int, ...]] = []
    cursor = 2 + n
    for _ in range(q):
        op = tuple(values[cursor:cursor + 5])
        cursor += 5
        if op[0] == 0:
            if not (0 <= op[1] < n and 0 <= op[2] < n and op[3] == 0 and op[4] == 0):
                return None
        elif op[0] == 1:
            if not (0 <= op[1] <= op[2] <= n and 0 <= op[3] <= op[4] <= n):
                return None
        else:
            return None
        operations.append(op)
    return n, points, operations


def expected_result(values: Sequence[int] | None, input_is_null: bool = False,
                    input_length: int | None = None) -> int:
    parsed = _parse(values, input_is_null, input_length)
    if parsed is None:
        return INVALID_RESULT
    n, points, operations = parsed
    checksum = 0
    ordinal = 0
    for op in operations:
        if op[0] == 0:
            points[op[1]] = op[2]
            continue
        _, x_left, x_right, y_low, y_high = op
        count = sum(
            1 for x, y in enumerate(points)
            if x_left <= x < x_right and y_low <= y < y_high
        )
        ordinal += 1
        checksum += ordinal * count
    return checksum
