"""Independent FIFO-sum oracle for the sliding-window aggregator contract."""

from __future__ import annotations

from collections.abc import Sequence

MAX_CAPACITY = 64
MAX_COUNT = 256
MAX_VALUE = 1_000_000
MAX_PARSEABLE_INPUT_LENGTH = MAX_COUNT + 3
I64_MIN = -(1 << 63)
I64_MAX = (1 << 63) - 1
INVALID_RESULT = I64_MIN


def expected_result(values: Sequence[int] | None) -> int:
    """Return the sum of the nonempty final window, or I64_MIN if invalid."""
    if (
        not isinstance(values, (list, tuple))
        or len(values) > MAX_PARSEABLE_INPUT_LENGTH
        or any(
            type(value) is not int or not I64_MIN <= value <= I64_MAX
            for value in values
        )
    ):
        return INVALID_RESULT
    if len(values) < 2:
        return INVALID_RESULT

    capacity, count = values[:2]
    if not 1 <= capacity <= MAX_CAPACITY or not 1 <= count <= MAX_COUNT:
        return INVALID_RESULT
    if len(values) != count + 2:
        return INVALID_RESULT

    elements = values[2:]
    if any(not -MAX_VALUE <= value <= MAX_VALUE for value in elements):
        return INVALID_RESULT
    return sum(elements[-capacity:])
