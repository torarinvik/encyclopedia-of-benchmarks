"""Independent byte-array oracle for Java ParseInteger int wraparound."""

from __future__ import annotations

MAX_INPUT_LENGTH = 64
I64_MIN = -(1 << 63)
I32_MODULUS = 1 << 32
I32_SIGN_BIT = 1 << 31


def expected_result(values: list[int]) -> int:
    if (not isinstance(values, list) or not 1 <= len(values) <= MAX_INPUT_LENGTH
            or any(type(value) is not int or not 0 <= value <= 127 for value in values)):
        return I64_MIN

    negative = values[0] == ord("-")
    offset = 1 if values[0] in (ord("+"), ord("-")) else 0
    number = 0
    for byte in values[offset:]:
        if not ord("0") <= byte <= ord("9"):
            return I64_MIN
        number = (number * 10 + byte - ord("0")) % I32_MODULUS
    if negative:
        number = (-number) % I32_MODULUS
    return number - I32_MODULUS if number >= I32_SIGN_BIT else number
