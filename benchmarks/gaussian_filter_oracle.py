"""Reference output for the bounded, fixed-point Gaussian image filter."""

from __future__ import annotations

SCALE = 1_000_000_000_000_000
MAX_DIMENSION = 12
MAX_INPUT_LENGTH = 3 + MAX_DIMENSION * MAX_DIMENSION
MAX_OUTPUT_BYTES = (MAX_DIMENSION - 3 + 1) ** 2

# Coefficients are the pinned source's Gaussian formula, rounded once to SCALE.
# This fixed-point form gives every target language the same truncation result.
WEIGHTS = {
    3: {0: 159154943091895, 1: 96532352630054, 2: 58549831524319},
    5: {
        0: 198943678864869,
        1: 91083053297916,
        2: 41700860491808,
        4: 8740975213082,
        5: 4001910066968,
        8: 384051647741,
    },
}


def expected_output(values: list[int]) -> tuple[int, bytes]:
    if (not isinstance(values, list) or len(values) < 3
            or len(values) > MAX_INPUT_LENGTH
            or any(type(value) is not int or not -(2**63) <= value < 2**63
                   for value in values)):
        return -1, b""

    height, width, kernel_size = values[:3]
    if (not 3 <= height <= MAX_DIMENSION or not 3 <= width <= MAX_DIMENSION
            or kernel_size not in (3, 5) or height < kernel_size or width < kernel_size
            or len(values) != 3 + height * width):
        return -1, b""

    pixels = values[3:]
    if any(not 0 <= pixel <= 255 for pixel in pixels):
        return -1, b""

    output_height = height - kernel_size + 1
    output_width = width - kernel_size + 1
    center = kernel_size // 2
    weights = WEIGHTS[kernel_size]
    output = bytearray(output_height * output_width)

    for output_row in range(output_height):
        for output_column in range(output_width):
            total = 0
            for kernel_row in range(kernel_size):
                dy = kernel_row - center
                for kernel_column in range(kernel_size):
                    dx = kernel_column - center
                    pixel = pixels[(output_row + kernel_row) * width
                                   + output_column + kernel_column]
                    total += pixel * weights[dx * dx + dy * dy]
            output[output_row * output_width + output_column] = total // SCALE

    return len(output), bytes(output)
