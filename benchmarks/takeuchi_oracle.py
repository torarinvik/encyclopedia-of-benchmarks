"""Independent bounded oracle for the integer Takeuchi recurrence."""

from __future__ import annotations

from functools import cache

MIN_INPUT = 0
MAX_INPUT = 12
INVALID_RESULT = -1


@cache
def takeuchi(x: int, y: int, z: int) -> int:
    if y < x:
        return takeuchi(
            takeuchi(x - 1, y, z),
            takeuchi(y - 1, z, x),
            takeuchi(z - 1, x, y),
        )
    return z


def expected_result(x: int, y: int, z: int) -> int:
    if any(type(value) is not int or not MIN_INPUT <= value <= MAX_INPUT
           for value in (x, y, z)):
        return INVALID_RESULT
    return takeuchi(x, y, z)
