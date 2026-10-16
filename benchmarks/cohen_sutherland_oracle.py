"""Independent bounded oracle for the Java Cohen-Sutherland clipper."""

from __future__ import annotations

SCALE = 1_000_000
MAX_COORDINATE_MICRO = 1_000_000_000
INVALID_RESULT = -1e300

INSIDE = 0
LEFT = 1
RIGHT = 2
BOTTOM = 4
TOP = 8


def _region_code(x: float, y: float, x_min: float, y_min: float, x_max: float, y_max: float) -> int:
    code = INSIDE
    if x < x_min:
        code |= LEFT
    elif x > x_max:
        code |= RIGHT
    if y < y_min:
        code |= BOTTOM
    elif y > y_max:
        code |= TOP
    return code


def _clip(values: list[int] | tuple[int, ...]) -> tuple[bool, float, float, float, float]:
    _, x_min_raw, y_min_raw, x_max_raw, y_max_raw, x1_raw, y1_raw, x2_raw, y2_raw = values
    x_min, y_min, x_max, y_max = (value / SCALE for value in (x_min_raw, y_min_raw, x_max_raw, y_max_raw))
    x1, y1, x2, y2 = (value / SCALE for value in (x1_raw, y1_raw, x2_raw, y2_raw))
    code1 = _region_code(x1, y1, x_min, y_min, x_max, y_max)
    code2 = _region_code(x2, y2, x_min, y_min, x_max, y_max)

    while True:
        if code1 == INSIDE and code2 == INSIDE:
            return True, x1, y1, x2, y2
        if code1 & code2:
            return False, x1, y1, x2, y2

        code_out = code1 if code1 != INSIDE else code2
        if code_out & TOP:
            x = x1 + (x2 - x1) * (y_max - y1) / (y2 - y1)
            y = y_max
        elif code_out & BOTTOM:
            x = x1 + (x2 - x1) * (y_min - y1) / (y2 - y1)
            y = y_min
        elif code_out & RIGHT:
            y = y1 + (y2 - y1) * (x_max - x1) / (x2 - x1)
            x = x_max
        else:
            y = y1 + (y2 - y1) * (x_min - x1) / (x2 - x1)
            x = x_min

        if code_out == code1:
            x1, y1 = x, y
            code1 = _region_code(x1, y1, x_min, y_min, x_max, y_max)
        else:
            x2, y2 = x, y
            code2 = _region_code(x2, y2, x_min, y_min, x_max, y_max)


def expected_result(values: list[int] | tuple[int, ...]) -> float:
    """Return the selected clipped endpoint coordinate or acceptance flag."""
    if (not isinstance(values, (list, tuple)) or len(values) != 9
            or any(type(value) is not int for value in values)):
        return INVALID_RESULT
    selector = values[0]
    if not 0 <= selector <= 4:
        return INVALID_RESULT
    coordinates = values[1:]
    if any(not -MAX_COORDINATE_MICRO <= value <= MAX_COORDINATE_MICRO for value in coordinates):
        return INVALID_RESULT
    _, x_min, y_min, x_max, y_max, _, _, _, _ = values
    if x_min >= x_max or y_min >= y_max:
        return INVALID_RESULT

    accepted, x1, y1, x2, y2 = _clip(values)
    if selector == 4:
        return 1.0 if accepted else 0.0
    if not accepted:
        return INVALID_RESULT
    return (x1, y1, x2, y2)[selector]
