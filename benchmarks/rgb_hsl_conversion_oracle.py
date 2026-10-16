"""Independent oracle for the bounded pinned RGB-to-HSL conversion."""

from __future__ import annotations

MAX_INPUT_LENGTH = 4
OUTPUT_LENGTH = 4
I64_MIN = -(1 << 63)
I64_MAX = (1 << 63) - 1


def _js_round(value: float) -> int:
    """JavaScript Math.round for the nonnegative HSL quantities here."""
    return int(value + 0.5)


def expected_output(values: list[int], capacity: int | None = None) -> tuple[int, bytes]:
    if (not isinstance(values, list) or len(values) != 3
            or any(type(value) is not int or not I64_MIN <= value <= I64_MAX
                   or not 0 <= value <= 255 for value in values)):
        return -1, b""
    if capacity is not None and (type(capacity) is not int or capacity < 0):
        return -1, b""
    if capacity is not None and capacity < OUTPUT_LENGTH:
        return -2, b""

    red, green, blue = (value / 255.0 for value in values)
    minimum = min(red, green, blue)
    maximum = max(red, green, blue)
    channel = 0
    if maximum == green:
        channel = 1
    elif maximum == blue:
        channel = 2

    luminance = (minimum + maximum) / 2.0
    saturation = 0.0
    if minimum != maximum:
        if luminance <= 0.5:
            saturation = (maximum - minimum) / (maximum + minimum)
        else:
            saturation = (maximum - minimum) / (2.0 - maximum - minimum)

    hue = 0.0
    if saturation != 0.0:
        if channel == 0:
            hue = (green - blue) / (maximum - minimum)
        elif channel == 1:
            hue = 2.0 + (blue - red) / (maximum - minimum)
        else:
            hue = 4.0 + (red - green) / (maximum - minimum)
    hue *= 60.0
    if hue < 0.0:
        hue += 360.0

    h = _js_round(hue)
    s = _js_round(saturation * 100.0)
    l = _js_round(luminance * 100.0)
    return OUTPUT_LENGTH, bytes((h & 0xFF, h >> 8, s, l))
