"""Bounded contract for the pinned C# RGB/HSV conversion routines."""
from __future__ import annotations

MAX_INPUT_LENGTH = 4
INVALID_RESULT = -1


def _round_even(value: float) -> int:
    return int(round(value))


def expected_result(values: list[int]) -> int:
    if len(values) != MAX_INPUT_LENGTH:
        return INVALID_RESULT
    op, a, b, c = values
    if op == 0:
        if not (0 <= a <= 360_000 and 0 <= b <= 1_000 and 0 <= c <= 1_000):
            return INVALID_RESULT
        hue, saturation, value = a / 1000.0, b / 1000.0, c / 1000.0
        chroma = value * saturation
        section = hue / 60.0
        second = chroma * (1.0 - abs(section % 2.0 - 1.0))
        match = value - chroma
        if 0 <= section <= 1:
            rgb = (chroma + match, second + match, match)
        elif section <= 2:
            rgb = (second + match, chroma + match, match)
        elif section <= 3:
            rgb = (match, chroma + match, second + match)
        elif section <= 4:
            rgb = (match, second + match, chroma + match)
        elif section <= 5:
            rgb = (second + match, match, chroma + match)
        else:
            rgb = (chroma + match, match, second + match)
        r, g, bl = (_round_even(255.0 * component) for component in rgb)
        return (r << 16) | (g << 8) | bl
    if op == 1:
        if any(x < 0 or x > 255 for x in (a, b, c)):
            return INVALID_RESULT
        red, green, blue = (x / 255.0 for x in (a, b, c))
        value = max(red, green, blue)
        chroma = value - min(red, green, blue)
        saturation = 0.0 if value == 0.0 else chroma / value
        if chroma == 0.0:
            hue = 0.0
        elif value == red:
            hue = 60.0 * ((green - blue) / chroma)
        elif value == green:
            hue = 60.0 * (2.0 + (blue - red) / chroma)
        else:
            hue = 60.0 * (4.0 + (red - green) / chroma)
        hue = (hue + 360.0) % 360.0
        hq, sq, vq = _round_even(hue * 1000.0), _round_even(saturation * 1_000_000.0), _round_even(value * 1_000_000.0)
        return (hq << 40) | (sq << 20) | vq
    return INVALID_RESULT
