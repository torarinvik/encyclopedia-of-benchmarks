"""Independent oracle for the bounded AArch64 UTF-8 length extraction."""

from __future__ import annotations

from collections.abc import Sequence

INVALID_RESULT = -1
OUTPUT_ERROR_RESULT = -2
MAX_PAYLOAD_BYTES = 256
MAX_VALID_INPUT_LENGTH = MAX_PAYLOAD_BYTES + 2
MAX_PARSEABLE_INPUT_LENGTH = MAX_VALID_INPUT_LENGTH + 1
MAX_OUTPUT_BYTES = 16
I64_MIN = -(1 << 63)
I64_MAX = (1 << 63) - 1


def expected_result(
    values: Sequence[int] | None,
    output_capacity: int,
    output_is_null: bool = False,
    input_is_null: bool = False,
    input_length: int | None = None,
) -> tuple[int, bytes]:
    """Return the ABI result and the two little-endian i64 output words."""
    if (type(output_is_null) is not bool or type(input_is_null) is not bool
            or type(output_capacity) is not int or output_capacity < 0):
        return INVALID_RESULT, b""
    if input_is_null:
        if ((values is not None and values != [] and values != ())
                or type(input_length) is not int
                or not 1 <= input_length <= MAX_PARSEABLE_INPUT_LENGTH):
            return INVALID_RESULT, b""
        return INVALID_RESULT, b""
    if values is None:
        return INVALID_RESULT, b""
    if (not isinstance(values, (list, tuple))
            or len(values) < 2
            or len(values) > MAX_PARSEABLE_INPUT_LENGTH
            or (input_length is not None
                and (type(input_length) is not int or input_length != len(values)))
            or any(type(value) is not int or not I64_MIN <= value <= I64_MAX for value in values)):
        return INVALID_RESULT, b""

    payload_length = values[0]
    if (not 0 <= payload_length <= MAX_PAYLOAD_BYTES
            or len(values) != payload_length + 2
            or any(value < 0 or value > 255 for value in values[1:])
            or values[-1] != 0
            or any(value == 0 for value in values[1:-1])):
        return INVALID_RESULT, b""

    try:
        text = bytes(values[1:-1]).decode("utf-8")
    except UnicodeDecodeError:
        return INVALID_RESULT, b""
    if any(ord(character) > 0xFFFF for character in text):
        return INVALID_RESULT, b""

    output = payload_length.to_bytes(8, "little", signed=True)
    output += len(text).to_bytes(8, "little", signed=True)
    if output_is_null or output_capacity < MAX_OUTPUT_BYTES:
        return OUTPUT_ERROR_RESULT, b""
    return MAX_OUTPUT_BYTES, output
