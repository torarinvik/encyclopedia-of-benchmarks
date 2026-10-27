"""Independent direct suffix comparison oracle for the bounded DC3 profile."""

from __future__ import annotations

import struct
from collections.abc import Sequence

MAX_TEXT_LENGTH = 16
MAX_INPUT_LENGTH = MAX_TEXT_LENGTH + 2
MAX_OUTPUT_BYTES = 8 * MAX_TEXT_LENGTH


def expected_output(values: Sequence[int] | None, capacity: int | None = None,
                    output_is_null: bool = False, input_is_null: bool = False,
                    input_length: int | None = None) -> tuple[int, bytes]:
    invalid = -1
    output_error = -2
    if (type(output_is_null) is not bool or type(input_is_null) is not bool
            or capacity is not None and (type(capacity) is not int or capacity < 0)
            or input_length is not None and (type(input_length) is not int
                                             or not 0 <= input_length <= MAX_INPUT_LENGTH)
            or input_is_null and values not in (None, [], ())
            or not input_is_null and values is not None and input_length is not None
            and input_length != len(values)):
        return invalid, b""
    if input_is_null or not isinstance(values, (list, tuple)):
        return invalid, b""
    if not 1 <= len(values) <= MAX_INPUT_LENGTH:
        return invalid, b""
    if any(type(value) is not int or not -(1 << 63) <= value < (1 << 63) for value in values):
        return invalid, b""
    count = values[0]
    if not 0 <= count <= MAX_TEXT_LENGTH or len(values) != count + 1:
        return invalid, b""
    symbols = values[1:]
    if any(not 0 <= symbol <= 255 for symbol in symbols):
        return invalid, b""

    suffix_order = sorted(range(count), key=lambda start: tuple(symbols[start:]))
    payload = struct.pack("<" + "q" * count, *suffix_order)
    if output_is_null or capacity is not None and capacity < len(payload):
        return output_error, b""
    return len(payload), payload
