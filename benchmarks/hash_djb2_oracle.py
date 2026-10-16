"""Independent oracle for the bounded 64-bit DJB2 byte hash."""

from __future__ import annotations

from collections.abc import Sequence

MAX_BYTES = 3
MAX_INPUT_LENGTH = MAX_BYTES + 1
INVALID_RESULT = -1
I64_MIN, I64_MAX = -(1 << 63), (1 << 63) - 1


def expected_result(values: Sequence[int]) -> int:
    if (
        not isinstance(values, (list, tuple))
        or not 1 <= len(values) <= MAX_INPUT_LENGTH
        or any(type(value) is not int or not I64_MIN <= value <= I64_MAX for value in values)
    ):
        return INVALID_RESULT
    count = values[0]
    if not 0 <= count <= MAX_BYTES or len(values) != count + 1:
        return INVALID_RESULT
    byte_values = values[1:]
    if any(not 1 <= byte <= 127 for byte in byte_values):
        return INVALID_RESULT
    result = 5381
    for byte in byte_values:
        result = result * 33 + byte
    return result
