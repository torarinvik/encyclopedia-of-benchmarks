"""Independent oracle for the bounded BEEBS LCD digit-to-segment profile."""

from __future__ import annotations

MAX_VALID_INPUT_LENGTH = 5
MAX_INPUT_LENGTH = 5
MAX_PARSEABLE_INPUT_LENGTH = 6
MAX_OUTPUT_BYTES = 5
INVALID_RESULT = -1
OUTPUT_ERROR = -2
SEGMENT_MASKS = (0x00, 0x24, 0x5D, 0x6D, 0x2E, 0x5D, 0x7B, 0x25,
                 0x7F, 0x6F, 0x3F, 0x7A, 0x53, 0x7C, 0x5B, 0x1B)


def expected_output(values: list[int] | tuple[int, ...], capacity: int | None = None,
                    output_is_null: bool = False, input_is_null: bool = False,
                    input_length: int | None = None) -> tuple[int, bytes]:
    """Map five raw byte values through the source low-nibble LCD lookup."""
    if type(output_is_null) is not bool or type(input_is_null) is not bool:
        return INVALID_RESULT, b""
    if input_is_null:
        return INVALID_RESULT, b""
    if (not isinstance(values, (list, tuple))
            or any(type(value) is not int or not -(1 << 63) <= value < (1 << 63)
                   for value in values)
            or len(values) != MAX_VALID_INPUT_LENGTH
            or (input_length is not None
                and (type(input_length) is not int or input_length != len(values)))
            or any(not 0 <= value <= 255 for value in values)):
        return INVALID_RESULT, b""
    if capacity is not None and (type(capacity) is not int or capacity < 0):
        return INVALID_RESULT, b""
    if output_is_null or (capacity is not None and capacity < MAX_OUTPUT_BYTES):
        return OUTPUT_ERROR, b""
    output = bytes(SEGMENT_MASKS[value & 0x0F] for value in values)
    return len(output), output
