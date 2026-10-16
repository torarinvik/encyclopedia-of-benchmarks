"""Bounded oracle for the pinned 1.5x nearest-neighbor image zoom loop."""

from __future__ import annotations

MAX_DIMENSION = 16
MAX_INPUT_LENGTH = 2 + MAX_DIMENSION * MAX_DIMENSION
MAX_OUTPUT_BYTES = 24 * 24
INVALID_RESULT = -1
INSUFFICIENT_CAPACITY = -2
I64_MIN, I64_MAX = -(1 << 63), (1 << 63) - 1


def _nearest_source_index(output_index: int) -> int:
    """Translate a zero-based output index to MATLAB's one-based round(i/1.5)."""
    one_based_source_index = (4 * (output_index + 1) + 3) // 6
    return one_based_source_index - 1


def expected_output(values: tuple[int, ...] | list[int],
                    output_capacity: int | None = None) -> tuple[int, bytes]:
    if (not isinstance(values, (tuple, list)) or not 2 <= len(values) <= MAX_INPUT_LENGTH
            or any(type(value) is not int or not I64_MIN <= value <= I64_MAX for value in values)):
        return INVALID_RESULT, b""
    rows, columns = values[:2]
    if not 1 <= rows <= MAX_DIMENSION or not 1 <= columns <= MAX_DIMENSION:
        return INVALID_RESULT, b""
    cell_count = rows * columns
    if len(values) != 2 + cell_count:
        return INVALID_RESULT, b""
    pixels = values[2:]
    if any(not 0 <= value <= 255 for value in pixels):
        return INVALID_RESULT, b""
    if output_capacity is not None and (type(output_capacity) is not int or output_capacity < 0):
        return INVALID_RESULT, b""

    output_rows = (3 * rows) // 2
    output_columns = (3 * columns) // 2
    output_bytes = output_rows * output_columns
    if output_capacity is not None and output_capacity < output_bytes:
        return INSUFFICIENT_CAPACITY, b""

    output = bytearray(output_bytes)
    for y in range(output_rows):
        source_y = _nearest_source_index(y)
        for x in range(output_columns):
            source_x = _nearest_source_index(x)
            output[y * output_columns + x] = pixels[source_y * columns + source_x]
    return output_bytes, bytes(output)
