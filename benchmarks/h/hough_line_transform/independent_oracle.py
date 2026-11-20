"""Independent bin-scanning reference for the bounded Hough accumulator."""

from __future__ import annotations

from collections.abc import Sequence

from .primary_oracle import (
    ANGLE_NORMALS,
    ANGLE_COUNT,
    INVALID_RESULT,
    MAX_HEIGHT,
    MAX_OUTPUT_BYTES,
    MAX_PARSEABLE_INPUT_LENGTH,
    MAX_WIDTH,
    OUTPUT_ERROR_RESULT,
    RHO_BIN_COUNT,
    RHO_MAX,
    RHO_MIN,
)


def _grid(values: Sequence[int] | None, input_is_null: bool,
          input_length: int | None):
    if (type(input_is_null) is not bool or input_is_null
            or not isinstance(values, (list, tuple))
            or not 3 <= len(values) <= MAX_PARSEABLE_INPUT_LENGTH
            or any(type(word) is not int or not -(1 << 63) <= word < (1 << 63)
                   for word in values)):
        return None
    if input_length is not None and (
            type(input_length) is not int or input_length != len(values)):
        return None
    height, width = values[:2]
    if not 1 <= height <= MAX_HEIGHT or not 1 <= width <= MAX_WIDTH:
        return None
    if len(values) != 2 + height * width:
        return None
    pixels = values[2:]
    if any(pixel not in (0, 1) for pixel in pixels):
        return None
    return height, width, pixels


def expected_output(values: Sequence[int] | None, *, capacity: int,
                    output_is_null: bool = False,
                    input_is_null: bool = False,
                    input_length: int | None = None) -> tuple[int, bytes]:
    parsed = _grid(values, input_is_null, input_length)
    if parsed is None:
        return INVALID_RESULT, b""
    if (type(capacity) is not int or capacity < 0
            or type(output_is_null) is not bool):
        return OUTPUT_ERROR_RESULT, b""
    if output_is_null or capacity < MAX_OUTPUT_BYTES:
        return OUTPUT_ERROR_RESULT, b""

    height, width, pixels = parsed
    output = bytearray()
    for angle in range(ANGLE_COUNT):
        normal_x, normal_y = ANGLE_NORMALS[angle]
        for rho in range(RHO_MIN, RHO_MAX + 1):
            count = 0
            for row in range(height):
                for column in range(width):
                    if (pixels[row * width + column] == 1
                            and normal_x * column + normal_y * row == rho):
                        count += 1
            output.append(count)
    return RHO_BIN_COUNT * ANGLE_COUNT, bytes(output)
