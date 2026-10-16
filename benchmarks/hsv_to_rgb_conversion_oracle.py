"""Pinned JavaScript HSV-to-RGB oracle with exact source midpoint rounding."""

from __future__ import annotations

MAX_INPUT_LENGTH = 3
MAX_PARSEABLE_INPUT_LENGTH = 4
MAX_HUE_MILLIDEGREES = 360_000
MAX_COMPONENT_SCALED = 255_000_000
OUTPUT_BYTES = 3
I64_MIN = -(1 << 63)
I64_MAX = (1 << 63) - 1


def expected_output(values: list[int], capacity: int | None = None) -> tuple[int, bytes]:
    if (not isinstance(values, list) or len(values) != MAX_INPUT_LENGTH
            or any(type(value) is not int or not I64_MIN <= value <= I64_MAX for value in values)):
        return -1, b""
    hue_code, saturation_code, value_code = values
    if (not 0 <= hue_code <= MAX_HUE_MILLIDEGREES
            or not 0 <= saturation_code <= MAX_COMPONENT_SCALED
            or not 0 <= value_code <= MAX_COMPONENT_SCALED):
        return -1, b""
    if capacity is not None and (type(capacity) is not int or capacity < 0):
        return -1, b""
    if capacity is not None and capacity < OUTPUT_BYTES:
        return -2, b""

    hue = hue_code / 1000.0
    saturation = saturation_code / float(MAX_COMPONENT_SCALED)
    value = value_code / float(MAX_COMPONENT_SCALED)
    chroma = value * saturation
    hue_section = hue / 60.0
    second_largest_component = chroma * (1.0 - abs((hue_section % 2.0) - 1.0))
    match_value = value - chroma

    if 0.0 <= hue_section <= 1.0:
        red, green, blue = chroma + match_value, second_largest_component + match_value, match_value
    elif 1.0 < hue_section <= 2.0:
        red, green, blue = second_largest_component + match_value, chroma + match_value, match_value
    elif 2.0 < hue_section <= 3.0:
        red, green, blue = match_value, chroma + match_value, second_largest_component + match_value
    elif 3.0 < hue_section <= 4.0:
        red, green, blue = match_value, second_largest_component + match_value, chroma + match_value
    elif 4.0 < hue_section <= 5.0:
        red, green, blue = second_largest_component + match_value, match_value, chroma + match_value
    else:
        red, green, blue = chroma + match_value, match_value, second_largest_component + match_value

    # All valid channels are nonnegative, so floor(x + 0.5) is JS Math.round(x).
    rgb = tuple(int(255.0 * channel + 0.5) for channel in (red, green, blue))
    return OUTPUT_BYTES, bytes(rgb)
