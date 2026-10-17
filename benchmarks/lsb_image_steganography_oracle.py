"""Independent bounded oracle for row-major grayscale LSB message embedding."""
from __future__ import annotations

from typing import Sequence

MIN_DIMENSION = 1
MAX_DIMENSION = 16
MAX_MESSAGE_BYTES = 32
MAX_PIXELS = MAX_DIMENSION * MAX_DIMENSION
MAX_INPUT_LENGTH = 3 + MAX_PIXELS + MAX_MESSAGE_BYTES
MAX_PARSEABLE_INPUT_LENGTH = MAX_INPUT_LENGTH + 1
MAX_OUTPUT_BYTES = MAX_PIXELS
I64_MIN = -(1 << 63)
I64_MAX = (1 << 63) - 1
INVALID_RESULT = -1
INSUFFICIENT_OUTPUT_RESULT = -2


def expected_output(
    values: Sequence[int],
    output_capacity: int = MAX_OUTPUT_BYTES,
    output_is_null: bool = False,
    input_is_null: bool = False,
) -> tuple[int, bytes]:
    """Return (pixel_count/error, resulting row-major grayscale pixel bytes)."""
    if type(input_is_null) is not bool or type(output_is_null) is not bool:
        return INVALID_RESULT, b""
    if input_is_null:
        return INVALID_RESULT, b""
    if (
        not isinstance(values, (tuple, list))
        or len(values) < 3
        or len(values) > MAX_PARSEABLE_INPUT_LENGTH
        or any(type(value) is not int or not I64_MIN <= value <= I64_MAX for value in values)
    ):
        return INVALID_RESULT, b""

    rows, columns, message_length = values[:3]
    if not MIN_DIMENSION <= rows <= MAX_DIMENSION or not MIN_DIMENSION <= columns <= MAX_DIMENSION:
        return INVALID_RESULT, b""
    if not 0 <= message_length <= MAX_MESSAGE_BYTES:
        return INVALID_RESULT, b""
    pixel_count = rows * columns
    if message_length * 8 > pixel_count:
        return INVALID_RESULT, b""
    if len(values) != 3 + pixel_count + message_length:
        return INVALID_RESULT, b""

    pixels = values[3:3 + pixel_count]
    message = values[3 + pixel_count:]
    if any(pixel < 0 or pixel > 254 for pixel in pixels):
        return INVALID_RESULT, b""
    if any(byte < 0 or byte > 127 for byte in message):
        return INVALID_RESULT, b""
    if type(output_capacity) is not int or output_capacity < 0:
        return INVALID_RESULT, b""
    if output_is_null or output_capacity < pixel_count:
        return INSUFFICIENT_OUTPUT_RESULT, b""

    result = list(pixels)
    bit_index = 0
    for byte in message:
        for shift in range(7, -1, -1):
            bit = (byte >> shift) & 1
            if (result[bit_index] & 1) != bit:
                result[bit_index] += 1
            bit_index += 1
    return pixel_count, bytes(result)
