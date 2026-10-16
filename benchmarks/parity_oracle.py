"""Independent full-range signed-i64 parity oracles."""

from __future__ import annotations

I64_MIN = -(2**63)
I64_MAX = 2**63 - 1


def check_even(value: int) -> int:
    if type(value) is not int or not I64_MIN <= value <= I64_MAX:
        return -1
    return int(value % 2 == 0)


def is_odd(value: int) -> int:
    if type(value) is not int or not I64_MIN <= value <= I64_MAX:
        return -1
    return int(value % 2 != 0)
