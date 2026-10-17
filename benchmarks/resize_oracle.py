"""Oracle for bounded, source-faithful RGB nearest-neighbor resize."""

from __future__ import annotations

from collections.abc import Sequence

MIN_DIMENSION = 1
MAX_DIMENSION = 32
CHANNELS = 3
HEADER_LENGTH = 4
MAX_VALID_INPUT_LENGTH = HEADER_LENGTH + CHANNELS * MAX_DIMENSION * MAX_DIMENSION
MAX_PARSEABLE_INPUT_LENGTH = MAX_VALID_INPUT_LENGTH + 1
MAX_INPUT_LENGTH = MAX_PARSEABLE_INPUT_LENGTH
MAX_OUTPUT_BYTES = CHANNELS * MAX_DIMENSION * MAX_DIMENSION
INVALID_RESULT = -1
CAPACITY_ERROR = -2
I64_MIN = -(1 << 63)
I64_MAX = (1 << 63) - 1


def expected_output(
    values: Sequence[int],
    capacity: int | None = None,
    output_is_null: bool = False,
) -> tuple[int, bytes]:
    if (
        not isinstance(values, (list, tuple))
        or not HEADER_LENGTH <= len(values) <= MAX_PARSEABLE_INPUT_LENGTH
        or any(
            type(value) is not int or not I64_MIN <= value <= I64_MAX
            for value in values
        )
    ):
        return INVALID_RESULT, b""

    src_width, src_height, dst_width, dst_height = values[:HEADER_LENGTH]
    if any(
        not MIN_DIMENSION <= dimension <= MAX_DIMENSION
        for dimension in (src_width, src_height, dst_width, dst_height)
    ):
        return INVALID_RESULT, b""

    expected_input_length = HEADER_LENGTH + CHANNELS * src_width * src_height
    if len(values) != expected_input_length:
        return INVALID_RESULT, b""

    pixels = values[HEADER_LENGTH:]
    if any(type(channel) is not int or not 0 <= channel <= 255 for channel in pixels):
        return INVALID_RESULT, b""

    # Match the source's constructor ratios and get_x/get_y multiplication order.
    ratio_x = src_width / dst_width
    ratio_y = src_height / dst_height
    output = bytearray(CHANNELS * dst_width * dst_height)
    out_index = 0
    for y in range(dst_height):
        source_y = int(ratio_y * y)
        for x in range(dst_width):
            source_x = int(ratio_x * x)
            source_index = CHANNELS * (source_y * src_width + source_x)
            output[out_index : out_index + CHANNELS] = bytes(
                pixels[source_index : source_index + CHANNELS]
            )
            out_index += CHANNELS

    result = bytes(output)
    if output_is_null or (
        capacity is not None
        and (type(capacity) is not int or capacity < len(result))
    ):
        return CAPACITY_ERROR, b""
    return len(result), result


def expected_result(
    values: Sequence[int],
    capacity: int | None = None,
    output_is_null: bool = False,
) -> tuple[int, bytes]:
    return expected_output(values, capacity, output_is_null)
