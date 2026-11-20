"""Foreground-pixel vote accumulator for the bounded Hough profile."""

from __future__ import annotations

from collections.abc import Sequence

MAX_HEIGHT = 8
MAX_WIDTH = 8
MAX_CELLS = MAX_HEIGHT * MAX_WIDTH
MAX_VALID_INPUT_LENGTH = 2 + MAX_CELLS
MAX_PARSEABLE_INPUT_LENGTH = MAX_VALID_INPUT_LENGTH + 1
ANGLE_NORMALS = ((1, 0), (1, 1), (0, 1), (-1, 1))
RHO_MIN = -14
RHO_MAX = 14
RHO_BIN_COUNT = RHO_MAX - RHO_MIN + 1
ANGLE_COUNT = len(ANGLE_NORMALS)
MAX_OUTPUT_BYTES = ANGLE_COUNT * RHO_BIN_COUNT
INVALID_RESULT = -1
OUTPUT_ERROR_RESULT = -2


def _parse(values: Sequence[int] | None, input_is_null: bool,
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
    cells = height * width
    if len(values) != 2 + cells:
        return None
    pixels = values[2:]
    if any(pixel not in (0, 1) for pixel in pixels):
        return None
    return height, width, pixels


def expected_output(values: Sequence[int] | None,
                    capacity: int = MAX_OUTPUT_BYTES,
                    output_is_null: bool = False,
                    input_is_null: bool = False,
                    input_length: int | None = None) -> tuple[int, bytes]:
    parsed = _parse(values, input_is_null, input_length)
    if parsed is None:
        return INVALID_RESULT, b""
    if (type(capacity) is not int or capacity < 0
            or type(output_is_null) is not bool):
        return OUTPUT_ERROR_RESULT, b""
    if output_is_null or capacity < MAX_OUTPUT_BYTES:
        return OUTPUT_ERROR_RESULT, b""

    height, width, pixels = parsed
    accumulator = [0] * MAX_OUTPUT_BYTES
    for row in range(height):
        for column in range(width):
            if pixels[row * width + column] == 0:
                continue
            x, y = column, row
            for angle, (normal_x, normal_y) in enumerate(ANGLE_NORMALS):
                rho = normal_x * x + normal_y * y
                index = angle * RHO_BIN_COUNT + rho - RHO_MIN
                accumulator[index] += 1
    return MAX_OUTPUT_BYTES, bytes(accumulator)
