"""Independent oracle for cBench's bounded fixed-point RGB-to-gray core."""

from __future__ import annotations

from collections.abc import Sequence

INVALID_RESULT = -1
OUTPUT_ERROR = -2
MAX_PIXELS = 64
MAX_INPUT_LENGTH = 1 + 3 * MAX_PIXELS
MAX_OUTPUT_BYTES = MAX_PIXELS
I64_MIN = -(1 << 63)
I64_MAX = (1 << 63) - 1

# tiff2bw's PCT macro uses integer division: (channel_percent * 255) / 100.
RED_WEIGHT = 71
GREEN_WEIGHT = 150
BLUE_WEIGHT = 28


def expected_output(
    values: Sequence[int] | None,
    output_capacity: int | None = None,
    output_is_null: bool = False,
    input_is_null: bool = False,
    input_length: int | None = None,
) -> tuple[int, bytes]:
    if (
        type(output_is_null) is not bool
        or type(input_is_null) is not bool
        or output_capacity is not None
        and (type(output_capacity) is not int or output_capacity < 0)
        or input_length is not None
        and (type(input_length) is not int or not 0 <= input_length <= MAX_INPUT_LENGTH)
    ):
        return INVALID_RESULT, b""
    if input_is_null or values is None or not isinstance(values, (list, tuple)):
        return INVALID_RESULT, b""
    if (
        not 4 <= len(values) <= MAX_INPUT_LENGTH
        or any(type(value) is not int or not I64_MIN <= value <= I64_MAX for value in values)
        or input_length is not None and input_length != len(values)
    ):
        return INVALID_RESULT, b""

    count = values[0]
    if not 1 <= count <= MAX_PIXELS or len(values) != 1 + 3 * count:
        return INVALID_RESULT, b""
    channels = values[1:]
    if any(not 0 <= channel <= 255 for channel in channels):
        return INVALID_RESULT, b""
    if output_is_null or output_capacity is not None and output_capacity < count:
        return OUTPUT_ERROR, b""

    output = bytearray()
    for pixel in range(count):
        red, green, blue = channels[3 * pixel:3 * pixel + 3]
        weighted = RED_WEIGHT * red
        weighted += GREEN_WEIGHT * green
        weighted += BLUE_WEIGHT * blue
        output.append((weighted >> 8) & 0xFF)
    return count, bytes(output)
