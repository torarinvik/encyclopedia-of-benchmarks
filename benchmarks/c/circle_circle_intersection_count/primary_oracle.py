"""Exact radical-axis oracle for circle-circle intersection categories."""

from __future__ import annotations

MAX_COORDINATE = 1_000
MAX_RADIUS = 1_000
MAX_INPUT_LENGTH = 6
MAX_PARSEABLE_INPUT_LENGTH = 7


def expected_output(values, input_is_null=False, input_length=None):
    """Return 0/1/2 intersection points or 3 for coincident circles."""
    if input_is_null or not isinstance(values, (list, tuple)):
        return -1
    if (len(values) < 6 or len(values) > MAX_PARSEABLE_INPUT_LENGTH
            or any(type(value) is not int or not -(1 << 63) <= value < (1 << 63)
                   for value in values)):
        return -1
    if input_length is not None and (
        type(input_length) is not int or input_length != len(values)
    ):
        return -1
    if len(values) != MAX_INPUT_LENGTH:
        return -1
    x1, y1, r1, x2, y2, r2 = values
    if (not -MAX_COORDINATE <= x1 <= MAX_COORDINATE
            or not -MAX_COORDINATE <= y1 <= MAX_COORDINATE
            or not -MAX_COORDINATE <= x2 <= MAX_COORDINATE
            or not -MAX_COORDINATE <= y2 <= MAX_COORDINATE
            or not 1 <= r1 <= MAX_RADIUS
            or not 1 <= r2 <= MAX_RADIUS):
        return -1
    dx = x2 - x1
    dy = y2 - y1
    if dx == 0 and dy == 0:
        return 3 if r1 == r2 else 0

    # Translate the first center to the origin, then subtract the circle
    # equations to obtain the radical-axis line A*x+B*y+C=0.
    a = -2 * dx
    b = -2 * dy
    c = dx * dx + dy * dy + r1 * r1 - r2 * r2
    discriminant = r1 * r1 * (a * a + b * b) - c * c
    if discriminant < 0:
        return 0
    if discriminant == 0:
        return 1
    return 2
