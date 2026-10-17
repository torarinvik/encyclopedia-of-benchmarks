"""Independent checksum oracle for the bounded Smoothsort contract."""

from __future__ import annotations

from collections.abc import Sequence

MAX_N = 512
MIN_VALUE = -1_000_000
MAX_VALUE = 1_000_000
MAX_PARSEABLE_INPUT_LENGTH = MAX_N + 2
I64_MIN = -(1 << 63)
I64_MAX = (1 << 63) - 1
INVALID_RESULT = -1
OFFSET = 1_000_001


def expected_result(values: Sequence[int] | None) -> int:
    """Return the weighted checksum of ascending values, or -1 if invalid."""
    if (
        not isinstance(values, (list, tuple))
        or len(values) > MAX_PARSEABLE_INPUT_LENGTH
        or any(
            type(value) is not int or not I64_MIN <= value <= I64_MAX
            for value in values
        )
        or len(values) < 1
    ):
        return INVALID_RESULT

    n = values[0]
    if not 0 <= n <= MAX_N or len(values) != n + 1:
        return INVALID_RESULT
    array = values[1:]
    if any(not MIN_VALUE <= value <= MAX_VALUE for value in array):
        return INVALID_RESULT

    return sum(position * (value + OFFSET) for position, value in enumerate(sorted(array), start=1))
