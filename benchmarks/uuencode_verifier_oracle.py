"""Independent verifier model for the bounded BitBench uuencode stream."""

from __future__ import annotations

from collections.abc import Sequence

MAX_INPUT_BYTES = 4096
MAX_PARSEABLE_INPUT_VALUES = 4097
MAX_OUTPUT_BYTES = 5675
HEADER = bytes((98, 101, 103, 105, 110, 32, 54, 52, 48, 32,
                117, 117, 101, 110, 99, 111, 100, 101, 46, 99, 32, 10))
END_MARKER = bytes((32, 10, 101, 110, 100))
INVALID_RESULT = -1
OUTPUT_ERROR = -2


def _stream(values: Sequence[int]) -> bytes:
    result = bytearray(HEADER)
    for start in range(0, len(values), 45):
        chunk = values[start:start + 45]
        result.append(32 + len(chunk))
        for offset in range(0, len(chunk), 3):
            group = chunk[offset:offset + 3]
            packed = group[0] << 16
            if len(group) > 1:
                packed |= group[1] << 8
            if len(group) > 2:
                packed |= group[2]
            result.extend((
                32 + ((packed >> 18) & 63),
                32 + ((packed >> 12) & 63),
                32 + ((packed >> 6) & 63) if len(group) > 1 else 61,
                32 + (packed & 63) if len(group) > 2 else 61,
            ))
        result.append(10)
    result.extend(END_MARKER)
    return bytes(result)


def expected_output(values: Sequence[int] | None,
                    output_capacity: int | None = None,
                    output_is_null: bool = False,
                    input_is_null: bool = False,
                    input_length: int | None = None) -> tuple[int, bytes]:
    if (type(output_is_null) is not bool or type(input_is_null) is not bool
            or (output_capacity is not None
                and (type(output_capacity) is not int or output_capacity < 0))
            or (input_length is not None
                and (type(input_length) is not int or input_length < 0))):
        return INVALID_RESULT, b""
    if (input_is_null or values is None or not isinstance(values, (tuple, list))
            or len(values) > MAX_PARSEABLE_INPUT_VALUES
            or (input_length is not None and input_length != len(values))
            or len(values) > MAX_INPUT_BYTES
            or any(type(value) is not int or not 0 <= value <= 255 for value in values)):
        return INVALID_RESULT, b""
    stream = _stream(values)
    if output_is_null or (output_capacity is not None and output_capacity < len(stream)):
        return OUTPUT_ERROR, b""
    return len(stream), stream
