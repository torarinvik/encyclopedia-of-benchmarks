"""Independent bounded oracle for contiguous sublist search."""

from __future__ import annotations

from typing import Sequence

MAX_LIST_LENGTH = 64
MAX_INPUT_LENGTH = 2 + 2 * MAX_LIST_LENGTH
MAX_VALUE = (1 << 31) - 1
I64_MIN = -(1 << 63)
I64_MAX = (1 << 63) - 1
INVALID_RESULT = -1


def expected_result(values: Sequence[int]) -> int:
    """Return 1 for a contiguous match, 0 for a miss, or -1 for invalid input."""
    if (
        not isinstance(values, (tuple, list))
        or len(values) < 2
        or len(values) > MAX_INPUT_LENGTH
        or any(type(value) is not int or value < I64_MIN or value > I64_MAX for value in values)
    ):
        return INVALID_RESULT

    main_count, pattern_count = values[:2]
    if not 0 <= main_count <= MAX_LIST_LENGTH or not 0 <= pattern_count <= MAX_LIST_LENGTH:
        return INVALID_RESULT
    if len(values) != 2 + main_count + pattern_count:
        return INVALID_RESULT
    main = values[2 : 2 + main_count]
    pattern = values[2 + main_count :]
    if any(value < 0 or value > MAX_VALUE for value in (*main, *pattern)):
        return INVALID_RESULT

    # In the source, an empty linked-list head for either list is false.
    if not main or not pattern or len(pattern) > len(main):
        return 0

    last_start = len(main) - len(pattern)
    for start in range(last_start + 1):
        if all(main[start + offset] == expected
               for offset, expected in enumerate(pattern)):
            return 1
    return 0
