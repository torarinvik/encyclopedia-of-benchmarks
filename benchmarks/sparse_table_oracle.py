"""Independent linear-scan oracle for the sparse-table RMQ contract."""

from __future__ import annotations

from collections.abc import Sequence

MAX_N = 12_344  # The source LOG array is indexed through n and has size 12,345.
MAX_PARSEABLE_INPUT_LENGTH = MAX_N + 4
I64_MIN = -(1 << 63)
I64_MAX = (1 << 63) - 1


def expected_result(values: Sequence[int] | None) -> int:
    """Return the leftmost minimum index in one inclusive range, or -1."""
    if (
        not isinstance(values, (list, tuple))
        or not 1 <= len(values) <= MAX_PARSEABLE_INPUT_LENGTH
        or any(type(value) is not int or not I64_MIN <= value <= I64_MAX for value in values)
    ):
        return -1
    n = values[0]
    if not 1 <= n <= MAX_N or len(values) != n + 3:
        return -1
    left, right = values[-2:]
    if not 0 <= left <= right < n:
        return -1

    array = values[1 : n + 1]
    minimum_index = left
    for index in range(left + 1, right + 1):
        if array[index] < array[minimum_index]:
            minimum_index = index
    return minimum_index
