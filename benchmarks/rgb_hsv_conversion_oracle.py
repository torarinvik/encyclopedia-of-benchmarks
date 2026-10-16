"""Independent binary64 oracle for the pinned integer-RGB to HSV conversion."""

from __future__ import annotations

import struct

MAX_INPUT_LENGTH = 3
MAX_PARSEABLE_INPUT_LENGTH = 4
OUTPUT_LENGTH = 24
I64_MIN = -(1 << 63)
I64_MAX = (1 << 63) - 1


def expected_output(values: list[int], capacity: int | None = None) -> tuple[int, bytes]:
    if (not isinstance(values, list) or len(values) != MAX_INPUT_LENGTH
            or any(type(value) is not int or not I64_MIN <= value <= I64_MAX
                   or not 0 <= value <= 255 for value in values)):
        return -1, b""
    if capacity is not None and (type(capacity) is not int or capacity < 0):
        return -1, b""
    if capacity is not None and capacity < OUTPUT_LENGTH:
        return -2, b""

    red, green, blue = (value / 255.0 for value in values)
    value = max(max(red, green), blue)
    chroma = value - min(min(red, green), blue)
    saturation = 0.0 if value == 0.0 else chroma / value
    if chroma == 0.0:
        hue = 0.0
    elif value == red:
        hue = 60.0 * (0.0 + (green - blue) / chroma)
    elif value == green:
        hue = 60.0 * (2.0 + (blue - red) / chroma)
    else:
        hue = 60.0 * (4.0 + (red - green) / chroma)
    hue = (hue + 360.0) % 360.0
    return OUTPUT_LENGTH, struct.pack("<ddd", hue, saturation, value)
