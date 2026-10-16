"""Oracle for the bounded eight-selector Rust trigonometry operation."""

from __future__ import annotations

import math

MIN_X, MAX_X = -10_000.0, 10_000.0
MIN_TOLERANCE, MAX_TOLERANCE = 1e-9, 1e-2
PERIOD = 2.0 * math.pi


def _round_six(value: float) -> float:
    scaled = abs(value) * 1_000_000.0
    rounded = math.floor(scaled + 0.5)
    if value < 0.0:
        rounded = -rounded
    return rounded / 1_000_000.0


def _series(value: float, tolerance: float, kind: int) -> float:
    while value >= PERIOD:
        value -= PERIOD
    while value <= -PERIOD:
        value += PERIOD

    result = 0.0
    previous = 1.0
    step = 0
    while abs(previous - result) > tolerance:
        previous = result
        power = 2 * step + kind
        term = math.factorial(power)
        result += ((-1.0) ** step) * (value ** power) / float(term)
        step += 1
    return _round_six(result)


def expected_result(values: list[float] | tuple[float, ...]) -> list[float] | None:
    if (not isinstance(values, (list, tuple)) or len(values) != 3
            or any(type(value) not in (int, float) for value in values)):
        return None
    selector_value, raw_x, raw_tolerance = (float(value) for value in values)
    if (not math.isfinite(selector_value) or selector_value != math.floor(selector_value)
            or not 0 <= selector_value <= 7):
        return None
    selector = int(selector_value)
    if (not math.isfinite(raw_tolerance)
            or not MIN_TOLERANCE <= raw_tolerance <= MAX_TOLERANCE):
        return None
    if math.isfinite(raw_x):
        if not MIN_X <= raw_x <= MAX_X:
            return None
    else:
        return [math.nan]

    value = raw_x
    if selector in (2, 3, 6, 7):
        value = value * math.pi / 180.0
    if selector in (0, 2):
        return [_series(value, raw_tolerance, 1)]
    if selector in (1, 3):
        return [_series(value, raw_tolerance, 0)]
    if selector in (4, 6):
        denominator = _series(value, raw_tolerance, 0)
        if denominator == 0.0:
            return [math.nan]
        return [_series(value, raw_tolerance, 1) / denominator]
    numerator = _series(value, raw_tolerance, 0)
    denominator = _series(value, raw_tolerance, 1)
    if denominator == 0.0:
        return [math.nan]
    return [numerator / denominator]
