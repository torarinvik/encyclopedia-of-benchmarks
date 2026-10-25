"""Independent bounded oracle for TSVC Searching-dbl s331."""

from __future__ import annotations

MAX_LENGTH = 256
MIN_VALUE = -1_000_000
MAX_VALUE = 1_000_000
MAX_INPUT_LENGTH = 1 + MAX_LENGTH


def expected_result(values: list[int] | tuple[int, ...] | None) -> int:
    if (values is None or not isinstance(values, (list, tuple))
            or len(values) < 1 or len(values) > MAX_INPUT_LENGTH
            or any(type(value) is not int for value in values)):
        return -1
    n = values[0]
    if not 1 <= n <= MAX_LENGTH or len(values) != n + 1:
        return -1
    if any(value < MIN_VALUE or value > MAX_VALUE for value in values[1:]):
        return -1
    result = 0
    for index, value in enumerate(values[1:]):
        if value < 0:
            result = index + 1
    return result
