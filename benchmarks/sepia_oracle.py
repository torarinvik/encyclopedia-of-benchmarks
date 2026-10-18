"""Oracle for the bounded, source-faithful Python sepia transform."""

from __future__ import annotations

from collections.abc import Sequence

MIN_DIMENSION = 1
MAX_DIMENSION = 8
MIN_FACTOR = 0
MAX_FACTOR = 255
PIXEL_LEVELS = frozenset((0, 64, 128, 255))
MAX_PIXELS = MAX_DIMENSION * MAX_DIMENSION
MAX_VALID_INPUT_LENGTH = 3 + 3 * MAX_PIXELS
MAX_PARSEABLE_INPUT_LENGTH = MAX_VALID_INPUT_LENGTH + 1
MAX_OUTPUT_BYTES = 3 * MAX_PIXELS
INVALID_RESULT = -1
OUTPUT_ERROR = -2


def _decode_input(values: Sequence[int] | None):
    if (not isinstance(values, (list, tuple))
            or not 3 <= len(values) <= MAX_PARSEABLE_INPUT_LENGTH):
        return None
    if any(type(value) is not int or not -(1 << 63) <= value < (1 << 63)
           for value in values):
        return None

    height, width, factor = values[:3]
    if (not MIN_DIMENSION <= height <= MAX_DIMENSION
            or not MIN_DIMENSION <= width <= MAX_DIMENSION
            or not MIN_FACTOR <= factor <= MAX_FACTOR):
        return None
    expected_length = 3 + 3 * height * width
    if len(values) != expected_length:
        return None
    pixels = values[3:]
    if any(value not in PIXEL_LEVELS for value in pixels):
        return None
    return height, width, factor, pixels


def _transform(pixels: Sequence[int], factor: int) -> bytes:
    output = bytearray()
    for offset in range(0, len(pixels), 3):
        blue, green, red = pixels[offset:offset + 3]
        gray = int(0.2126 * red + 0.587 * green + 0.114 * blue)
        output.extend((gray, min(gray + factor, 255), min(gray + 2 * factor, 255)))
    return bytes(output)


def expected_output(
    values: Sequence[int] | None,
    capacity: int | None = None,
    output_is_null: bool = False,
    input_is_null: bool = False,
    input_length: int | None = None,
) -> tuple[int, bytes]:
    """Return transformed BGR pixels or the documented ABI error."""
    if type(output_is_null) is not bool or type(input_is_null) is not bool:
        return INVALID_RESULT, b""
    if input_is_null or values is None or not isinstance(values, (list, tuple)):
        return INVALID_RESULT, b""
    if input_length is not None and (
        type(input_length) is not int or input_length != len(values)
    ):
        return INVALID_RESULT, b""

    decoded = _decode_input(values)
    if decoded is None:
        return INVALID_RESULT, b""
    _, _, factor, pixels = decoded
    output = _transform(pixels, factor)
    if len(output) > MAX_OUTPUT_BYTES:
        return INVALID_RESULT, b""
    if capacity is not None and (type(capacity) is not int or capacity < 0):
        return INVALID_RESULT, b""
    if output_is_null or (capacity is not None and capacity < len(output)):
        return OUTPUT_ERROR, b""
    return len(output), output
