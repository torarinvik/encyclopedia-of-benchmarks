"""Oracle for the bounded edge-replicated image-convolution benchmark."""

from __future__ import annotations

import struct

MAX_SIDE = 16
MAX_KERNEL_SIDE = 7
MAX_INPUT_LENGTH = 308
MAX_OUTPUT_BYTES = MAX_SIDE * MAX_SIDE * 8


def expected_output(values: list[int] | tuple[int, ...],
                    capacity: int | None = None) -> tuple[int, bytes]:
    """Return row-major integer convolution results as little-endian i64 bytes."""
    if (not isinstance(values, (list, tuple)) or not 3 <= len(values) <= MAX_INPUT_LENGTH
            or any(type(value) is not int or not -(2**63) <= value < 2**63 for value in values)):
        return -1, b""
    side, kernel_side = values[:2]
    if not 1 <= side <= MAX_SIDE or not 1 <= kernel_side <= MAX_KERNEL_SIDE or kernel_side % 2 == 0:
        return -1, b""
    pixel_count = side * side
    kernel_count = kernel_side * kernel_side
    if len(values) != 2 + pixel_count + kernel_count:
        return -1, b""
    pixels = values[2:2 + pixel_count]
    kernel = values[2 + pixel_count:]
    if any(not 0 <= pixel <= 255 for pixel in pixels):
        return -1, b""
    if any(not -16 <= weight <= 16 for weight in kernel):
        return -1, b""

    output_bytes = pixel_count * 8
    if capacity is not None:
        if type(capacity) is not int or capacity < 0:
            return -1, b""
        if output_bytes > capacity:
            return -2, b""

    radius = kernel_side // 2
    result: list[int] = []
    for row in range(side):
        for column in range(side):
            total = 0
            for kernel_row in range(kernel_side):
                source_row = min(side - 1, max(0, row + kernel_row - radius))
                for kernel_column in range(kernel_side):
                    source_column = min(side - 1, max(0, column + kernel_column - radius))
                    pixel = pixels[source_row * side + source_column]
                    weight = kernel[kernel_row * kernel_side + kernel_column]
                    total += pixel * weight
            result.append(total)
    return output_bytes, struct.pack("<" + "q" * len(result), *result)
