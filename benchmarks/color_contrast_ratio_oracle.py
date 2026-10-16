"""Source-backed oracle for the Java ColorContrastRatio benchmark."""

from __future__ import annotations

INVALID_RESULT = -1e300


def _component(channel: int) -> float:
    srgb = channel / 255.0
    if srgb <= 0.03928:
        return srgb / 12.92
    return ((srgb + 0.055) / 1.055) ** 2.4


def _luminance(red: int, green: int, blue: int) -> float:
    return (0.2126 * _component(red)
            + 0.7152 * _component(green)
            + 0.0722 * _component(blue))


def expected_result(values: list[int] | tuple[int, ...]) -> float:
    """Return the pinned Java formula for six RGB channels or the ABI sentinel."""
    if (len(values) != 6
            or any(type(value) is not int or value < 0 or value > 255 for value in values)):
        return INVALID_RESULT

    first = _luminance(values[0], values[1], values[2])
    second = _luminance(values[3], values[4], values[5])
    if first > second:
        return (first + 0.05) / (second + 0.05)
    return (second + 0.05) / (first + 0.05)
