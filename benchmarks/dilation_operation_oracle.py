"""Independent oracle for bounded binary 3x3 morphological dilation."""

from __future__ import annotations

import struct

MAX_DIMENSION = 16
KERNEL_CELLS = 9
MAX_INPUT_LENGTH = 2 + MAX_DIMENSION * MAX_DIMENSION + KERNEL_CELLS
MAX_OUTPUT_BYTES = MAX_DIMENSION * MAX_DIMENSION * 4
I64_MIN, I64_MAX = -(1 << 63), (1 << 63) - 1


def expected_output(values: tuple[int, ...] | list[int],
                    output_capacity: int | None = None) -> tuple[int, bytes]:
    """Return the row-major 0/1 mask for an image and fixed 3x3 kernel."""
    if (not isinstance(values, (tuple, list)) or not 12 <= len(values) <= MAX_INPUT_LENGTH
            or any(type(value) is not int or not I64_MIN <= value <= I64_MAX for value in values)):
        return -1, b""
    rows, columns = values[:2]
    if not 1 <= rows <= MAX_DIMENSION or not 1 <= columns <= MAX_DIMENSION:
        return -1, b""
    cell_count = rows * columns
    if len(values) != 2 + cell_count + KERNEL_CELLS:
        return -1, b""
    image = values[2:2 + cell_count]
    kernel = values[2 + cell_count:]
    if any(value not in (0, 1) for value in (*image, *kernel)):
        return -1, b""
    if output_capacity is not None and (type(output_capacity) is not int or output_capacity < 0):
        return -1, b""
    output_bytes = cell_count * 4
    if output_capacity is not None and output_capacity < output_bytes:
        return -2, b""

    output: list[int] = []
    for y in range(rows):
        for x in range(columns):
            overlap = 0
            for kernel_y in range(3):
                image_y = y + kernel_y - 1
                if not 0 <= image_y < rows:
                    continue
                for kernel_x in range(3):
                    image_x = x + kernel_x - 1
                    if 0 <= image_x < columns:
                        overlap += (image[image_y * columns + image_x]
                                    * kernel[kernel_y * 3 + kernel_x])
            output.append(int(overlap > 0))
    encoded = b"".join(struct.pack("<i", value) for value in output)
    return cell_count, encoded
