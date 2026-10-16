"""Independent byte-output oracle for Java hexadecimal-to-binary conversion."""

from __future__ import annotations

from collections.abc import Sequence

MAX_INPUT_LENGTH = 65
MAX_PARSEABLE_INPUT_LENGTH = MAX_INPUT_LENGTH + 1
I64_MIN, I64_MAX = -(1 << 63), (1 << 63) - 1
I32_MIN, I32_MAX = -(1 << 31), (1 << 31) - 1
MAX_OUTPUT_BYTES = 32
INVALID_RESULT = -1
INSUFFICIENT_CAPACITY_RESULT = -2


def expected_output(values: Sequence[int], capacity: int | None = None) -> tuple[int, bytes]:
    """Return Java's minimum-eight-bit binary text and its output status."""
    if (not isinstance(values, (list, tuple)) or len(values) > MAX_PARSEABLE_INPUT_LENGTH
            or any(type(value) is not int or not I64_MIN <= value <= I64_MAX for value in values)
            or not 1 <= len(values) <= MAX_INPUT_LENGTH):
        return INVALID_RESULT, b""
    if capacity is not None and (type(capacity) is not int or capacity < 0):
        return INVALID_RESULT, b""

    negative = values[0] == 45
    first_digit = 1 if values[0] in (43, 45) else 0
    if first_digit == len(values):
        return INVALID_RESULT, b""
    limit = -I32_MIN if negative else I32_MAX
    value = 0
    for code in values[first_digit:]:
        if 48 <= code <= 57:
            digit = code - 48
        elif 65 <= code <= 70:
            digit = code - 55
        elif 97 <= code <= 102:
            digit = code - 87
        else:
            return INVALID_RESULT, b""
        if value > (limit - digit) // 16:
            return INVALID_RESULT, b""
        value = value * 16 + digit

    if negative and value != 0:
        bit_pattern = (1 << 32) - value
        output = format(bit_pattern, "032b").encode("ascii")
    else:
        output = format(value, "b").zfill(8).encode("ascii")
    if capacity is not None and len(output) > capacity:
        return INSUFFICIENT_CAPACITY_RESULT, b""
    return len(output), output
