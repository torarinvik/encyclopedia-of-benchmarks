"""Validated XOR-fold reference for the bounded NMEA payload checksum."""

from __future__ import annotations

from collections.abc import Sequence

MAX_PAYLOAD_LENGTH = 76
MAX_VALID_INPUT_LENGTH = MAX_PAYLOAD_LENGTH + 1
MAX_PARSEABLE_INPUT_LENGTH = MAX_VALID_INPUT_LENGTH + 1
INVALID_RESULT = -1
I64_MIN, I64_MAX = -(1 << 63), (1 << 63) - 1


def _parse(values: Sequence[int] | None, input_is_null: bool,
           input_length: int | None) -> tuple[int, ...] | None:
    if (type(input_is_null) is not bool or input_is_null
            or not isinstance(values, (list, tuple))
            or not 1 <= len(values) <= MAX_PARSEABLE_INPUT_LENGTH
            or any(type(word) is not int or not I64_MIN <= word <= I64_MAX
                   for word in values)):
        return None
    if input_length is not None and (
            type(input_length) is not int or input_length != len(values)):
        return None
    payload_length = values[0]
    if (not 0 <= payload_length <= MAX_PAYLOAD_LENGTH
            or len(values) != payload_length + 1
            or any(not 0 <= byte <= 127 for byte in values[1:])):
        return None
    return tuple(values[1:])


def expected_result(values: Sequence[int] | None, input_is_null: bool = False,
                    input_length: int | None = None) -> int:
    payload = _parse(values, input_is_null, input_length)
    if payload is None:
        return INVALID_RESULT
    checksum = 0
    for byte in payload:
        checksum ^= byte
    return checksum
