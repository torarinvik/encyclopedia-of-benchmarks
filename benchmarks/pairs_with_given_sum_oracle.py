"""Oracle for counting all index pairs that sum to a target."""

from __future__ import annotations

I64_MIN = -(2**63)
I64_MAX = 2**63 - 1
I32_MIN = -(2**31)
I32_MAX = 2**31 - 1
MAX_VALUE_COUNT = 256
MAX_INPUT_LENGTH = MAX_VALUE_COUNT + 1
INVALID_RESULT = -2


def expected_result(values: list[int] | tuple[int, ...]) -> int:
    """Count pairs i < j, with malformed packed inputs rejected."""
    if (not isinstance(values, (list, tuple)) or not 1 <= len(values) <= MAX_INPUT_LENGTH
            or any(type(value) is not int or not I64_MIN <= value <= I64_MAX for value in values)):
        return INVALID_RESULT
    if any(value < I32_MIN or value > I32_MAX for value in values):
        return INVALID_RESULT
    target = values[0]
    items = values[1:]
    return sum(items[left] + items[right] == target
               for left in range(len(items))
               for right in range(left + 1, len(items)))
