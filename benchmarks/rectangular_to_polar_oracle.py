"""Oracle for the bounded Rust-canonical rectangular-to-polar conversion."""

from __future__ import annotations

import math

INVALID_RESULT = -1.0e300
MAX_ABS_COORDINATE = 1_000_000.0


def _round_to_two_decimals_away_from_zero(value: float) -> float:
    """Match Rust f64::round after scaling, including signed zero."""
    if value == 0.0:
        return value
    scaled = value * 100.0
    if scaled >= 0.0:
        units = math.trunc(scaled + 0.5)
        return units / 100.0
    units = math.trunc(scaled - 0.5)
    if units == 0:
        return -0.0
    return units / 100.0


def expected_result(values: list[float]) -> float:
    if (not isinstance(values, list) or len(values) != 3
            or any(type(value) not in (int, float) or not math.isfinite(value) for value in values)):
        return INVALID_RESULT
    real, imag, component = (float(value) for value in values)
    if (abs(real) > MAX_ABS_COORDINATE or abs(imag) > MAX_ABS_COORDINATE
            or component not in (0.0, 1.0)):
        return INVALID_RESULT
    if component == 0.0:
        result = math.sqrt(real * real + imag * imag)
    else:
        radians = math.atan2(imag, real)
        result = math.degrees(radians)
    return _round_to_two_decimals_away_from_zero(result)
