"""Oracle for the bounded perspective projection operation."""

from __future__ import annotations

import math

MAX_ABS_INPUT = 1_000_000.0
MIN_ABS_DENOMINATOR = 1e-6
MAX_ABS_OUTPUT = 1e25


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


def expected_result(values: list[float]) -> tuple[float, float] | None:
    """Project ``[x, y, z, scale, distance]`` or return None if out of domain."""
    converted = _finite_numbers(values)
    if converted is None:
        return None
    x, y, z, scale, distance = converted
    if any(abs(value) > MAX_ABS_INPUT for value in (x, y, z, scale, distance)):
        return None
    denominator = z + distance
    if abs(denominator) < MIN_ABS_DENOMINATOR:
        return None

    # Preserve the operation order in the pinned Python source.
    projected_x = ((x * distance) / denominator) * scale
    projected_y = ((y * distance) / denominator) * scale
    result = projected_x, projected_y
    if any(not math.isfinite(value) or abs(value) > MAX_ABS_OUTPUT for value in result):
        return None
    return result
