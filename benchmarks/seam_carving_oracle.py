"""Independent bounded oracle for one grayscale vertical seam removal."""

from __future__ import annotations

import math
from collections.abc import Sequence

MIN_WIDTH = 2
MAX_WIDTH = 6
MIN_HEIGHT = 1
MAX_HEIGHT = 6
MAX_INPUT_VALUES = 2 + MAX_WIDTH * MAX_HEIGHT
MAX_PARSEABLE_INPUT_VALUES = MAX_INPUT_VALUES + 1
MAX_OUTPUT_BYTES = (MAX_WIDTH - 1) * MAX_HEIGHT
INVALID_RESULT = -1
OUTPUT_ERROR = -2
I64_MIN = -(1 << 63)
I64_MAX = (1 << 63) - 1


def expected_output(
    values: Sequence[int] | None,
    output_capacity: int | None = None,
    output_is_null: bool = False,
    input_is_null: bool = False,
    input_length: int | None = None,
) -> tuple[int, bytes]:
    """Return row-major pixels after removing the minimum-energy vertical seam."""
    if type(output_is_null) is not bool or type(input_is_null) is not bool:
        return INVALID_RESULT, b""
    if output_capacity is not None and (
        type(output_capacity) is not int or output_capacity < 0
    ):
        return INVALID_RESULT, b""
    if input_length is not None and (
        type(input_length) is not int or input_length < 0
    ):
        return INVALID_RESULT, b""
    if input_is_null or values is None or not isinstance(values, (list, tuple)):
        return INVALID_RESULT, b""
    if not 2 <= len(values) <= MAX_PARSEABLE_INPUT_VALUES:
        return INVALID_RESULT, b""
    if input_length is not None and input_length != len(values):
        return INVALID_RESULT, b""
    if any(type(value) is not int or not I64_MIN <= value <= I64_MAX for value in values):
        return INVALID_RESULT, b""

    width, height = values[0], values[1]
    if not MIN_WIDTH <= width <= MAX_WIDTH or not MIN_HEIGHT <= height <= MAX_HEIGHT:
        return INVALID_RESULT, b""
    if len(values) != 2 + width * height:
        return INVALID_RESULT, b""
    pixels = values[2:]
    if any(not 0 <= value <= 255 for value in pixels):
        return INVALID_RESULT, b""

    # Trekhleb's RGB energy formula applied to grayscale pixels replicated into
    # R, G, and B. Preserve its per-pixel sqrt and cumulative DP additions.
    energy = [[0.0] * width for _ in range(height)]
    for y in range(height):
        row = y * width
        for x in range(width):
            middle = float(pixels[row + x])
            left_energy = 0.0
            if x > 0:
                difference = float(pixels[row + x - 1]) - middle
                left_energy = difference * difference + difference * difference + difference * difference
            right_energy = 0.0
            if x + 1 < width:
                difference = float(pixels[row + x + 1]) - middle
                right_energy = difference * difference + difference * difference + difference * difference
            energy[y][x] = math.sqrt(left_energy + right_energy)

    cumulative = [[0.0] * width for _ in range(height)]
    previous_x = [[-1] * width for _ in range(height)]
    for x in range(width):
        cumulative[0][x] = energy[0][x]
    for y in range(1, height):
        for x in range(width):
            best_previous_x = x
            best_previous_energy = math.inf
            for candidate_x in range(x - 1, x + 2):
                if (0 <= candidate_x < width
                        and cumulative[y - 1][candidate_x] < best_previous_energy):
                    best_previous_energy = cumulative[y - 1][candidate_x]
                    best_previous_x = candidate_x
            cumulative[y][x] = best_previous_energy + energy[y][x]
            previous_x[y][x] = best_previous_x

    seam_x = [0] * height
    last_x = 0
    minimum_energy = cumulative[height - 1][0]
    for x in range(1, width):
        if cumulative[height - 1][x] < minimum_energy:
            minimum_energy = cumulative[height - 1][x]
            last_x = x
    seam_x[height - 1] = last_x
    for y in range(height - 1, 0, -1):
        seam_x[y - 1] = previous_x[y][seam_x[y]]

    result = bytearray()
    for y in range(height):
        row = y * width
        for x in range(width):
            source_x = x if x < seam_x[y] else x + 1
            if source_x < width:
                result.append(pixels[row + source_x])

    output = bytes(result)
    if len(output) > MAX_OUTPUT_BYTES:
        return INVALID_RESULT, b""
    if output_is_null or (output_capacity is not None and output_capacity < len(output)):
        return OUTPUT_ERROR, b""
    return len(output), output
