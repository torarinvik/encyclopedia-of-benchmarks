"""Independent binary32-faithful oracle for bounded Koch point iteration."""
from __future__ import annotations

from collections.abc import Sequence
import math
import struct

MIN_POINT_COUNT = 2
MAX_POINT_COUNT = 8
MIN_STEPS = 0
MAX_STEPS = 1
MAX_COORDINATE = 1000.0
MAX_PARSEABLE_INPUT_LENGTH = 2 + 2 * (MAX_POINT_COUNT + 1)
MAX_VALID_INPUT_LENGTH = 2 + 2 * MAX_POINT_COUNT
MAX_OUTPUT_ELEMENTS = 2 * ((MAX_POINT_COUNT - 1) * (4 ** MAX_STEPS) + 1)
INVALID_RESULT = -1
OUTPUT_ERROR = -2


def _f32(value: float) -> float:
    return struct.unpack("<f", struct.pack("<f", value))[0]


def expected_result(values: Sequence[float] | None) -> list[float] | None:
    if (not isinstance(values, (list, tuple))
            or not 2 <= len(values) <= MAX_PARSEABLE_INPUT_LENGTH):
        return None
    if any(type(value) not in (int, float) for value in values):
        return None
    try:
        numbers = [float(value) for value in values]
    except (OverflowError, ValueError):
        return None
    if any(not math.isfinite(value) for value in numbers):
        return None
    step_value, count_value = numbers[:2]
    if (step_value != math.floor(step_value) or not MIN_STEPS <= step_value <= MAX_STEPS
            or count_value != math.floor(count_value)
            or not MIN_POINT_COUNT <= count_value <= MAX_POINT_COUNT):
        return None
    steps, count = int(step_value), int(count_value)
    if len(numbers) != 2 + 2 * count:
        return None
    coords = numbers[2:]
    if any(abs(value) > MAX_COORDINATE for value in coords):
        return None
    points = [(_f32(coords[index]), _f32(coords[index + 1]))
              for index in range(0, len(coords), 2)]
    radians = _f32(_f32(_f32(60.0) * _f32(math.pi)) / _f32(180.0))
    cos60 = _f32(math.cos(radians))
    sin60 = _f32(math.sin(radians))
    for _ in range(steps):
        expanded: list[tuple[float, float]] = []
        for (sx, sy), (ex, ey) in zip(points, points[1:]):
            dx = _f32(ex - sx)
            dy = _f32(ey - sy)
            third_x = _f32(dx / _f32(3.0))
            third_y = _f32(dy / _f32(3.0))
            first_x = _f32(sx + third_x)
            first_y = _f32(sy + third_y)
            rotated_x = _f32(_f32(cos60 * third_x) - _f32(sin60 * third_y))
            rotated_y = _f32(_f32(sin60 * third_x) + _f32(cos60 * third_y))
            peak_x = _f32(first_x + rotated_x)
            peak_y = _f32(first_y + rotated_y)
            two_thirds_x = _f32(_f32(dx * _f32(2.0)) / _f32(3.0))
            two_thirds_y = _f32(_f32(dy * _f32(2.0)) / _f32(3.0))
            expanded.extend(((sx, sy), (first_x, first_y), (peak_x, peak_y),
                             (_f32(sx + two_thirds_x), _f32(sy + two_thirds_y))))
        expanded.append(points[-1])
        points = expanded
    return [float(component) for point in points for component in point]
