"""Oracle for JavaScript FindMinIterator's default selector path."""

from __future__ import annotations

MAX_COUNT = 128
MAX_INPUT_LENGTH = MAX_COUNT + 1
MAX_VALUE = 2**31 - 1
INVALID_RESULT = -1

def expected_result(values: list[int]) -> int:
    if (not isinstance(values, list) or not 1 <= len(values) <= MAX_INPUT_LENGTH
            or any(type(value) is not int or not -(2**63) <= value <= 2**63 - 1
                   for value in values)):
        return INVALID_RESULT
    count = values[0]
    if not 0 <= count <= MAX_COUNT or len(values) != count + 1:
        return INVALID_RESULT
    if count == 0:
        return INVALID_RESULT
    items = values[1:]
    if any(not 0 <= value <= MAX_VALUE for value in items):
        return INVALID_RESULT
    return min(items)
