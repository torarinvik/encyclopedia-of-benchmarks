"""Bounded oracle for BitBench's fixed-header uuencode benchmark."""

from __future__ import annotations

from collections.abc import Sequence

MAX_INPUT_BYTES = 4096
MAX_PARSEABLE_INPUT_VALUES = MAX_INPUT_BYTES + 1
HEADER = b"begin 640 uuencode.c \n"
TRAILER = b" \nend"
MAX_OUTPUT_BYTES = len(HEADER) + 4 * ((MAX_INPUT_BYTES + 2) // 3) + 2 * ((MAX_INPUT_BYTES + 44) // 45) + len(TRAILER)
INVALID_RESULT = -1
OUTPUT_ERROR = -2


def _encode(data: Sequence[int]) -> bytes:
    """Encode source-order bytes using the benchmark's 45-byte line format."""
    output = bytearray(HEADER)
    offset = 0
    while offset < len(data):
        line_length = min(45, len(data) - offset)
        output.append(32 + line_length)
        end = offset + line_length
        while offset < end:
            first = data[offset]
            second = data[offset + 1] if offset + 1 < end else 0
            third = data[offset + 2] if offset + 2 < end else 0
            output.append(32 + ((first >> 2) & 63))
            output.append(32 + (((first << 4) | (second >> 4)) & 63))
            output.append(32 + (((second << 2) | (third >> 6)) & 63)
                          if offset + 1 < end else ord("="))
            output.append(32 + (third & 63) if offset + 2 < end else ord("="))
            offset += 3
        output.append(10)
    output.extend(TRAILER)
    return bytes(output)


def expected_output(values: Sequence[int] | None,
                    output_capacity: int | None = None,
                    output_is_null: bool = False,
                    input_is_null: bool = False,
                    input_length: int | None = None) -> tuple[int, bytes]:
    """Return the exact byte stream, or the suite's invalid/capacity result."""
    if (type(output_is_null) is not bool or type(input_is_null) is not bool
            or (output_capacity is not None
                and (type(output_capacity) is not int or output_capacity < 0))
            or (input_length is not None
                and (type(input_length) is not int or input_length < 0))):
        return INVALID_RESULT, b""
    if (input_is_null or values is None or not isinstance(values, (list, tuple))
            or len(values) > MAX_PARSEABLE_INPUT_VALUES
            or (input_length is not None and input_length != len(values))
            or any(type(value) is not int or not -(1 << 63) <= value < (1 << 63)
                   for value in values)
            or len(values) > MAX_INPUT_BYTES
            or any(not 0 <= value <= 255 for value in values)):
        return INVALID_RESULT, b""

    output = _encode(values)
    if output_is_null or (output_capacity is not None and output_capacity < len(output)):
        return OUTPUT_ERROR, b""
    return len(output), output
