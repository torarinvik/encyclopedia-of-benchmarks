"""Reference oracle for the bounded positive-integer binary length benchmark."""

from __future__ import annotations

MAX_INPUT = 2_147_483_647


def expected_result(value: int) -> int:
    if type(value) is not int or not 1 <= value <= MAX_INPUT:
        return -1
    return value.bit_length()
