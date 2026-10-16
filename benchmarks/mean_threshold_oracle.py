"""Bounded rectangular-grayscale contract for TheAlgorithms/Python mean_threshold."""

from __future__ import annotations

MAX_DIMENSION = 32
MAX_PIXEL_COUNT = MAX_DIMENSION * MAX_DIMENSION
MAX_INPUT_LENGTH = 2 + MAX_PIXEL_COUNT
MAX_PARSEABLE_INPUT_LENGTH = MAX_INPUT_LENGTH + 1
MAX_OUTPUT_BYTES = MAX_PIXEL_COUNT
INVALID_RESULT = -1
INSUFFICIENT_CAPACITY = -2


def expected_output(
    values: list[int] | tuple[int, ...],
    output_capacity: int = MAX_OUTPUT_BYTES,
) -> tuple[int, bytes]:
    """Return row-major 0/255 bytes using the source's floored global mean."""
    if (
        not isinstance(values, (list, tuple))
        or len(values) < 2
        or len(values) > MAX_PARSEABLE_INPUT_LENGTH
        or any(type(value) is not int or not -(2**63) <= value < 2**63 for value in values)
    ):
        return INVALID_RESULT, b""

    width, height = values[:2]
    if not 1 <= width <= MAX_DIMENSION or not 1 <= height <= MAX_DIMENSION:
        return INVALID_RESULT, b""
    pixel_count = width * height
    if len(values) != pixel_count + 2:
        return INVALID_RESULT, b""

    pixels = values[2:]
    if any(not 0 <= pixel <= 255 for pixel in pixels):
        return INVALID_RESULT, b""

    mean = sum(pixels) // pixel_count
    if output_capacity < pixel_count:
        return INSUFFICIENT_CAPACITY, b""
    output = bytes(255 if pixel > mean else 0 for pixel in pixels)
    return len(output), output

