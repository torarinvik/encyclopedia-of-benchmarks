"""Independent oracle for the bounded median-of-medians selection contract."""

from __future__ import annotations

MAX_ELEMENT_COUNT = 25
MAX_INPUT_LENGTH = MAX_ELEMENT_COUNT + 3  # one extra value reaches the ABI as malformed input
INT32_MAX = (1 << 31) - 1
INVALID_RESULT = -1


def expected_result(values: list[int] | tuple[int, ...]) -> int:
    if (not isinstance(values, (list, tuple))
            or len(values) < 3
            or len(values) > MAX_INPUT_LENGTH
            or any(type(value) is not int for value in values)):
        return INVALID_RESULT

    count, rank = values[:2]
    if not 1 <= count <= MAX_ELEMENT_COUNT or not 0 <= rank < count:
        return INVALID_RESULT
    if len(values) != count + 2:
        return INVALID_RESULT

    items = values[2:]
    if any(value < 0 or value > INT32_MAX for value in items):
        return INVALID_RESULT
    if len(set(items)) != count:
        return INVALID_RESULT
    return sorted(items)[rank]
