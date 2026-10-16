"""Oracle for the bounded axis rotation operation."""

from __future__ import annotations

import math

MAX_ABS_COORDINATE = 1_000_000.0
MAX_ABS_ANGLE = 1_000_000.0
MAX_ABS_OUTPUT = 2_000_000.0
AXIS_CODES = (0.0, 1.0, 2.0)  # x, y, z


def _finite_numbers(values: object) -> list[float] | None:
    if not isinstance(values, (list, tuple)) or len(values) != 5:
        return None
    converted: list[float] = []
    for value in values:
        if type(value) not in (int, float):
            return None
        try:
            number = float(value)
        except (OverflowError, ValueError):
            return None
        if not math.isfinite(number):
            return None
        converted.append(number)
    return converted


def expected_result(values: list[float]) -> tuple[float, float, float] | None:
    """Rotate ``[x, y, z, axis_code, angle]`` or return None if out of domain."""
    converted = _finite_numbers(values)
    if converted is None:
        return None
    x, y, z, axis_code, angle = converted
    if (any(abs(value) > MAX_ABS_COORDINATE for value in (x, y, z))
            or abs(angle) > MAX_ABS_ANGLE or axis_code not in AXIS_CODES):
        return None

    # Keep the pinned source's unusual conversion and evaluation order exactly.
    angle = (angle % 360.0) / 450.0 * 180.0 / math.pi
    cosine, sine = math.cos(angle), math.sin(angle)
    if axis_code == 0.0:
        result = x, y * cosine - z * sine, z * cosine + y * sine
    elif axis_code == 1.0:
        result = x * cosine - z * sine, y, z * cosine + x * sine
    else:
        result = x * cosine - y * sine, y * cosine + x * sine, z
    if any(not math.isfinite(value) or abs(value) > MAX_ABS_OUTPUT for value in result):
        return None
    return result
