"""Independent oracle for the positive signed-i64 Gregorian leap-year benchmark."""

from __future__ import annotations

I64_MIN = -(2**63)
I64_MAX = 2**63 - 1
INVALID_RESULT = -1


def expected_result(year: int) -> int:
    if type(year) is not int or not I64_MIN <= year <= I64_MAX or year <= 0:
        return INVALID_RESULT
    return int(year % 400 == 0 or (year % 4 == 0 and year % 100 != 0))
