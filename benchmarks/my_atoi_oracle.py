"""Oracle for the bounded Java MyAtoi byte-array adapter."""

from __future__ import annotations

I64_MIN = -(1 << 63)
I64_MAX = (1 << 63) - 1
MAX_INPUT_LENGTH = 256
INVALID_RESULT = I64_MIN
INT32_MIN = -(1 << 31)
INT32_MAX = (1 << 31) - 1


def expected_result(values: list[int] | tuple[int, ...]) -> int:
    """Return the parsed signed 32-bit value, or INT64_MIN for invalid input."""
    if (
        not isinstance(values, (list, tuple))
        or len(values) > MAX_INPUT_LENGTH
        or any(type(value) is not int or not I64_MIN <= value <= I64_MAX for value in values)
    ):
        return INVALID_RESULT
    if any(value < 0 or value > 127 for value in values):
        return INVALID_RESULT

    start = 0
    end = len(values)
    while start < end and values[start] <= 0x20:
        start += 1
    while end > start and values[end - 1] <= 0x20:
        end -= 1
    if start == end:
        return 0

    negative = False
    if values[start] in (ord("+"), ord("-")):
        negative = values[start] == ord("-")
        start += 1

    limit = -INT32_MIN if negative else INT32_MAX
    magnitude = 0
    saw_digit = False
    while start < end and ord("0") <= values[start] <= ord("9"):
        saw_digit = True
        digit = values[start] - ord("0")
        if magnitude > limit // 10 or (magnitude == limit // 10 and digit > limit % 10):
            return INT32_MIN if negative else INT32_MAX
        magnitude = magnitude * 10 + digit
        start += 1
    if not saw_digit:
        return 0
    return -magnitude if negative else magnitude
