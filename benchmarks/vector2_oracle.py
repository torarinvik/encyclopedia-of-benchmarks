"""Independent oracle for the bounded JavaScript Vector2 operation set."""

from __future__ import annotations

import math

MAX_INPUT_LENGTH = 6
COORDINATE_LIMIT = 1000.0
ANGLE_LIMIT = 6.283185307179586


def expected_result(values: list[float] | tuple[float, ...]) -> list[float] | None:
    if not isinstance(values, (list, tuple)) or len(values) != MAX_INPUT_LENGTH:
        return None
    try:
        numbers = [float(value) for value in values]
    except (TypeError, ValueError, OverflowError):
        return None
    if (any(type(value) not in (int, float) for value in values)
            or any(not math.isfinite(value) for value in numbers)):
        return None

    op_value, ax, ay, bx, by, scalar = numbers
    if not op_value.is_integer() or not 0 <= op_value <= 10:
        return None
    if any(abs(value) > COORDINATE_LIMIT for value in (ax, ay, bx, by)):
        return None
    op = int(op_value)

    if op == 1:
        if not 0.0 <= scalar <= 2000.0:
            return None
    elif op == 6:
        if bx != 0.0 or by != 0.0 or not -1000.0 <= scalar <= 1000.0:
            return None
    elif op == 9:
        if bx != 0.0 or by != 0.0 or abs(scalar) > ANGLE_LIMIT:
            return None
    else:
        if scalar != 0.0:
            return None
        if op in (2, 3) and (bx != 0.0 or by != 0.0):
            return None

    if op == 0:
        return [1.0 if ax == bx and ay == by else 0.0]
    if op == 1:
        return [1.0 if abs(ax - bx) < scalar and abs(ay - by) < scalar else 0.0]
    if op == 2:
        return [math.sqrt(ax * ax + ay * ay)]
    if op == 3:
        length = math.sqrt(ax * ax + ay * ay)
        if length == 0.0:
            return None
        return [ax / length, ay / length]
    if op == 4:
        return [ax + bx, ay + by]
    if op == 5:
        return [ax - bx, ay - by]
    if op == 6:
        return [ax * scalar, ay * scalar]
    if op == 7:
        dx = bx - ax
        dy = by - ay
        return [math.sqrt(dx * dx + dy * dy)]
    if op == 8:
        return [ax * bx + ay * by]
    if op == 9:
        cosine = math.cos(scalar)
        sine = math.sin(scalar)
        return [cosine * ax - sine * ay, sine * ax + cosine * ay]
    return [math.atan2(by, bx) - math.atan2(ay, ax)]
