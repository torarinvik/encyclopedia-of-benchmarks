"""Oracle for bounded recursive search over a singly linked list."""
from __future__ import annotations

MAX_NODES = 64
I32_MIN = -(1 << 31)
I32_MAX = (1 << 31) - 1
MAX_INPUT_LENGTH = MAX_NODES + 2
INVALID_RESULT = -1


def expected_result(values: list[int] | tuple[int, ...]) -> int:
    if (not isinstance(values, (list, tuple)) or len(values) < 2
            or len(values) > MAX_INPUT_LENGTH
            or any(type(value) is not int or not -(1 << 63) <= value < (1 << 63)
                   for value in values)):
        return INVALID_RESULT
    count, key = values[0], values[1]
    if not 0 <= count <= MAX_NODES or len(values) != count + 2:
        return INVALID_RESULT
    if not I32_MIN <= key <= I32_MAX or any(not I32_MIN <= value <= I32_MAX for value in values[2:]):
        return INVALID_RESULT
    return int(key in values[2:])
