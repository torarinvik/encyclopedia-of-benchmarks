"""Oracle for the pinned normalized absolute-gradient Sobel filter."""

from __future__ import annotations

from collections.abc import Sequence
import math

MAX_SIDE = 16
MAX_VALID_INPUT_LENGTH = 1 + MAX_SIDE * MAX_SIDE
MAX_PARSEABLE_INPUT_LENGTH = MAX_VALID_INPUT_LENGTH + 1
MAX_OUTPUT_ELEMENTS = 2 * MAX_SIDE * MAX_SIDE
MAX_OUTPUT_BYTES = 8 * MAX_OUTPUT_ELEMENTS
I64_MIN = -(1 << 63)
I64_MAX = (1 << 63) - 1
INVALID_RESULT = -1
OUTPUT_ERROR = -2

KERNEL_X = ((-1, 0, 1), (-2, 0, 2), (-1, 0, 1))
KERNEL_Y = ((1, 2, 1), (0, 0, 0), (-1, -2, -1))


class InvalidInput(ValueError):
    """Raised when a trace is outside the bounded source-compatible domain."""


def _validate_and_compute(values: Sequence[int]) -> list[float]:
    if not isinstance(values, (list, tuple)):
        raise InvalidInput("input must be a list or tuple")
    if not 2 <= len(values) <= MAX_PARSEABLE_INPUT_LENGTH:
        raise InvalidInput("input length is outside the parseable range")
    if any(type(value) is not int or not I64_MIN <= value <= I64_MAX for value in values):
        raise InvalidInput("input words must be signed 64-bit integers")

    side = values[0]
    if not 3 <= side <= MAX_SIDE or len(values) != 1 + side * side:
        raise InvalidInput("side or exact image framing is invalid")
    pixels = values[1:]
    if any(not 0 <= value <= 255 for value in pixels):
        raise InvalidInput("grayscale pixels must be in [0, 255]")

    image = [pixels[row * side : (row + 1) * side] for row in range(side)]
    gradient_x = [[0] * side for _ in range(side)]
    gradient_y = [[0] * side for _ in range(side)]
    max_x = 0
    max_y = 0
    for y in range(side):
        for x in range(side):
            gx = 0
            gy = 0
            for ky in range(3):
                sample_y = min(side - 1, max(0, y + ky - 1))
                for kx in range(3):
                    sample_x = min(side - 1, max(0, x + kx - 1))
                    value = image[sample_y][sample_x]
                    gx += value * KERNEL_X[ky][kx]
                    gy += value * KERNEL_Y[ky][kx]
            gradient_x[y][x] = abs(gx)
            gradient_y[y][x] = abs(gy)
            max_x = max(max_x, abs(gx))
            max_y = max(max_y, abs(gy))
    if max_x == 0 or max_y == 0:
        raise InvalidInput("both independently normalized gradient axes must be nonzero")

    scaled_x = [[float(value) * 255.0 / float(max_x) for value in row] for row in gradient_x]
    scaled_y = [[float(value) * 255.0 / float(max_y) for value in row] for row in gradient_y]
    magnitude = [
        [math.sqrt(scaled_x[y][x] ** 2 + scaled_y[y][x] ** 2) for x in range(side)]
        for y in range(side)
    ]
    maximum_magnitude = max(value for row in magnitude for value in row)
    if maximum_magnitude == 0:
        raise InvalidInput("normalized gradient magnitude must be nonzero")

    dst = [
        float(int(value * 255.0 / maximum_magnitude))
        for row in magnitude
        for value in row
    ]
    theta = [
        math.atan2(scaled_y[y][x], scaled_x[y][x])
        for y in range(side)
        for x in range(side)
    ]
    return dst + theta


def expected_output(
    values: Sequence[int] | None,
    output_capacity: int | None = None,
    output_is_null: bool = False,
    input_is_null: bool = False,
    input_length: int | None = None,
) -> tuple[int, list[float]]:
    """Return the output vector and ABI result count or error sentinel."""
    if type(output_is_null) is not bool or type(input_is_null) is not bool:
        return INVALID_RESULT, []
    if input_length is not None and (
        type(input_length) is not int or input_length < 0
    ):
        return INVALID_RESULT, []
    if output_capacity is not None and (
        type(output_capacity) is not int or output_capacity < 0
    ):
        return INVALID_RESULT, []
    if input_is_null or values is None:
        return INVALID_RESULT, []
    if not isinstance(values, (list, tuple)):
        return INVALID_RESULT, []
    if input_length is not None and input_length != len(values):
        return INVALID_RESULT, []
    try:
        output = _validate_and_compute(values)
    except InvalidInput:
        return INVALID_RESULT, []

    output_bytes = len(output) * 8
    if output_is_null or (output_capacity is not None and output_capacity < output_bytes):
        return OUTPUT_ERROR, []
    return len(output), output
