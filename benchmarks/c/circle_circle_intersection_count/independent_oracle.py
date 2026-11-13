"""Squared-distance oracle for circle-circle intersection categories."""

from __future__ import annotations

MAX_COORDINATE = 1_000
MAX_RADIUS = 1_000
MAX_INPUT_LENGTH = 6
MAX_PARSEABLE_INPUT_LENGTH = 7


def expected_output(values, input_is_null=False, input_length=None):
    """Classify with exact distance versus sum/difference-radius thresholds."""
    if input_is_null or not isinstance(values, (tuple, list)):
        return -1
    if len(values) < 6 or len(values) > MAX_PARSEABLE_INPUT_LENGTH:
        return -1
    for value in values:
        if type(value) is not int or not -(1 << 63) <= value < (1 << 63):
            return -1
    if input_length is not None and (
        type(input_length) is not int or input_length != len(values)
    ):
        return -1
    if len(values) != 6:
        return -1
    x1, y1, r1, x2, y2, r2 = values
    if any(abs(coordinate) > MAX_COORDINATE
           for coordinate in (x1, y1, x2, y2)):
        return -1
    if not 1 <= r1 <= MAX_RADIUS or not 1 <= r2 <= MAX_RADIUS:
        return -1

    dx = x2 - x1
    dy = y2 - y1
    if dx == 0 and dy == 0:
        return 3 if r1 == r2 else 0
    distance_squared = dx * dx + dy * dy
    sum_squared = (r1 + r2) ** 2
    difference_squared = abs(r1 - r2) ** 2
    if distance_squared > sum_squared or distance_squared < difference_squared:
        return 0
    if distance_squared == sum_squared or distance_squared == difference_squared:
        return 1
    return 2
