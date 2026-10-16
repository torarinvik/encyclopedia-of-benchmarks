"""Bounded oracle for the pinned C++ backward Jump Game scan."""

from __future__ import annotations

INVALID_RESULT = -2
MAX_ARRAY_LENGTH = 1_024
MAX_INPUT_LENGTH = MAX_ARRAY_LENGTH + 1
MAX_JUMP = 1_000_000


def expected_result(values: tuple[int, ...] | list[int]) -> int:
    if (not isinstance(values, (tuple, list)) or not 2 <= len(values) <= MAX_INPUT_LENGTH
            or any(type(value) is not int or not -(2**63) <= value < 2**63 for value in values)):
        return INVALID_RESULT
    count, *jumps = values
    if (not 1 <= count <= MAX_ARRAY_LENGTH or len(jumps) != count
            or any(not 0 <= jump <= MAX_JUMP for jump in jumps)):
        return INVALID_RESULT

    last_position = count - 1
    for index in range(last_position, -1, -1):
        if index + jumps[index] >= last_position:
            last_position = index
    return int(last_position == 0)
