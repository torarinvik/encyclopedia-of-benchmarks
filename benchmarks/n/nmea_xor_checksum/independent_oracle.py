"""Bit-parity reference for the bounded NMEA payload checksum."""

from __future__ import annotations

from collections.abc import Sequence

MAX_PAYLOAD_LENGTH = 76
MAX_PARSEABLE_INPUT_LENGTH = 78
INVALID_RESULT = -1
I64_MIN, I64_MAX = -(1 << 63), (1 << 63) - 1


def expected_result(values: Sequence[int] | None, input_is_null: bool = False,
                    input_length: int | None = None) -> int:
    if (type(input_is_null) is not bool or input_is_null
            or not isinstance(values, (list, tuple))
            or not 1 <= len(values) <= MAX_PARSEABLE_INPUT_LENGTH
            or any(type(word) is not int or not I64_MIN <= word <= I64_MAX
                   for word in values)):
        return INVALID_RESULT
    if input_length is not None and (
            type(input_length) is not int or input_length != len(values)):
        return INVALID_RESULT
    count = values[0]
    if not 0 <= count <= MAX_PAYLOAD_LENGTH or len(values) != count + 1:
        return INVALID_RESULT
    payload = values[1:]
    if any(not 0 <= byte <= 127 for byte in payload):
        return INVALID_RESULT
    checksum = 0
    for bit in range(7):
        if sum((byte >> bit) & 1 for byte in payload) % 2:
            checksum |= 1 << bit
    return checksum
