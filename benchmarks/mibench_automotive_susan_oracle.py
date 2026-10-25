"""Independent oracle for the bounded MiBench SUSAN smoothing profile."""
from __future__ import annotations

from collections.abc import Sequence
import math
import struct

MIN_SIDE = 15
MAX_SIDE = 16
MAX_VALID_INPUT_LENGTH = 1 + MAX_SIDE * MAX_SIDE
MAX_PARSEABLE_INPUT_LENGTH = MAX_VALID_INPUT_LENGTH + 1
MAX_OUTPUT_BYTES = MAX_SIDE * MAX_SIDE
BRIGHTNESS_THRESHOLD = 20
DISTANCE_THRESHOLD = 4
MASK_RADIUS = 7
INVALID_RESULT = -1
OUTPUT_ERROR = -2
I64_MIN = -(1 << 63)
I64_MAX = (1 << 63) - 1


class InvalidInput(ValueError):
    """Raised internally when a trace is outside the bounded contract."""


def _f32(value: float) -> float:
    """Round through IEEE binary32, matching the source's float temporaries."""
    return struct.unpack("=f", struct.pack("=f", value))[0]


def _brightness_lut() -> tuple[int, ...]:
    weights = []
    for difference in range(-255, 256):
        quotient = _f32(_f32(float(difference)) / _f32(float(BRIGHTNESS_THRESHOLD)))
        square = _f32(quotient * quotient)
        rounded = _f32(100.0 * math.exp(-square))
        weights.append(int(rounded))
    return tuple(weights)


def _distance_mask() -> tuple[tuple[int, ...], ...]:
    rows = []
    for dy in range(-MASK_RADIUS, MASK_RADIUS + 1):
        row = []
        for dx in range(-MASK_RADIUS, MASK_RADIUS + 1):
            distance_squared = _f32(float(dx * dx + dy * dy))
            exponent = _f32(distance_squared / _f32(-float(DISTANCE_THRESHOLD * DISTANCE_THRESHOLD)))
            row.append(int(100.0 * math.exp(exponent)))
        rows.append(tuple(row))
    return tuple(rows)


def _reflect(index: int, side: int) -> int:
    if index < 0:
        return -index - 1
    if index >= side:
        return 2 * side - index - 1
    return index


def _median_eight(image: Sequence[int], side: int, y: int, x: int) -> int:
    neighbors = []
    for dy in (-1, 0, 1):
        for dx in (-1, 0, 1):
            if dx == 0 and dy == 0:
                continue
            sample_y = _reflect(y + dy, side)
            sample_x = _reflect(x + dx, side)
            neighbors.append(image[sample_y * side + sample_x])
    neighbors.sort()
    return (neighbors[3] + neighbors[4]) // 2


def _smooth(image: Sequence[int], side: int) -> bytes:
    brightness = _brightness_lut()
    distance = _distance_mask()
    result = bytearray(side * side)
    for y in range(side):
        for x in range(side):
            center = image[y * side + x]
            area = 0
            total = 0
            for mask_y, dy in enumerate(range(-MASK_RADIUS, MASK_RADIUS + 1)):
                source_y = _reflect(y + dy, side)
                for mask_x, dx in enumerate(range(-MASK_RADIUS, MASK_RADIUS + 1)):
                    source_x = _reflect(x + dx, side)
                    pixel = image[source_y * side + source_x]
                    contribution = distance[mask_y][mask_x] * brightness[center - pixel + 255]
                    area += contribution
                    total += contribution * pixel
            denominator = area - 10_000
            if denominator == 0:
                result[y * side + x] = _median_eight(image, side, y, x)
            else:
                result[y * side + x] = (total - center * 10_000) // denominator
    return bytes(result)


def expected_output(
    values: Sequence[int] | None,
    output_capacity: int | None = None,
    output_is_null: bool = False,
    input_is_null: bool = False,
    input_length: int | None = None,
) -> tuple[int, bytes]:
    """Return the raw grayscale output plane and byte-count/error result."""
    if (type(output_is_null) is not bool or type(input_is_null) is not bool
            or (input_length is not None
                and (type(input_length) is not int or input_length < 0))
            or (output_capacity is not None
                and (type(output_capacity) is not int or output_capacity < 0))):
        return INVALID_RESULT, b""
    if input_is_null or values is None or not isinstance(values, (tuple, list)):
        return INVALID_RESULT, b""
    if (input_length is not None and input_length != len(values)):
        return INVALID_RESULT, b""
    if (not 2 <= len(values) <= MAX_PARSEABLE_INPUT_LENGTH
            or any(type(value) is not int or not I64_MIN <= value <= I64_MAX
                   for value in values)):
        return INVALID_RESULT, b""
    side = values[0]
    if (not MIN_SIDE <= side <= MAX_SIDE or len(values) != 1 + side * side
            or any(not 0 <= pixel <= 255 for pixel in values[1:])):
        return INVALID_RESULT, b""
    if output_is_null or (output_capacity is not None and output_capacity < side * side):
        return OUTPUT_ERROR, b""
    return side * side, _smooth(values[1:], side)
