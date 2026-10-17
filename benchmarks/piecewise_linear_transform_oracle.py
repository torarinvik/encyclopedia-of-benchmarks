"""Oracle for the notebook's bounded grayscale contrast-stretch mapping."""

from __future__ import annotations

from collections.abc import Sequence


MAX_PIXELS = 256
MAX_INPUT_LENGTH = MAX_PIXELS + 1  # includes one over-limit malformed case
MAX_OUTPUT_BYTES = MAX_PIXELS
INVALID_RESULT = -1
OUTPUT_ERROR = -2


def _transform(pixel: int) -> int:
    """Apply the pinned first-cell expressions and uint8 truncation."""
    r1, s1, r2, s2 = 100, 50, 180, 200
    if 0 <= pixel and pixel <= r1:
        value = (s1 / r1) * pixel
    elif r1 <= pixel and pixel <= r2:
        value = ((s2 - s1) / (r2 - r1)) * (pixel - r1) + s1
    else:
        value = ((255 - s2) / (255 - r2)) * (pixel - r2) + s2
    return int(value)


def expected_output(
    values: Sequence[int],
    capacity: int | None = None,
    output_is_null: bool = False,
) -> tuple[int, bytes]:
    """Return `(status, output_bytes)` for one grayscale pixel array."""
    if (not isinstance(values, (list, tuple))
            or not 1 <= len(values) <= MAX_INPUT_LENGTH
            or any(type(value) is not int for value in values)):
        return INVALID_RESULT, b""
    if len(values) > MAX_PIXELS or any(not 0 <= value <= 255 for value in values):
        return INVALID_RESULT, b""

    output = bytes(_transform(pixel) for pixel in values)
    if type(output_is_null) is not bool:
        return INVALID_RESULT, b""
    if capacity is not None and (type(capacity) is not int or capacity < 0):
        return INVALID_RESULT, b""
    if output_is_null or (capacity is not None and len(output) > capacity):
        return OUTPUT_ERROR, b""
    return len(output), output
