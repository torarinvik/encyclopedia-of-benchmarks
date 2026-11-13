"""Direct ordered-pair oracle for three-dimensional dominance counts."""

from __future__ import annotations

MAX_N = 64
COORDINATE_MIN = -1000
COORDINATE_MAX = 1000
MAX_VALID_INPUT_LENGTH = 193
MAX_PARSEABLE_INPUT_LENGTH = 194
WORKSPACE_BYTES = 8192


def _parse(values, input_is_null=False, input_length=None):
    if input_is_null or not isinstance(values, (list, tuple)):
        return None
    if len(values) < 1 or len(values) > MAX_PARSEABLE_INPUT_LENGTH:
        return None
    if any(type(value) is not int or not -(1 << 63) <= value < (1 << 63)
           for value in values):
        return None
    if input_length is not None and (
        type(input_length) is not int or input_length != len(values)
    ):
        return None
    n = values[0]
    if not 1 <= n <= MAX_N or len(values) != 1 + 3 * n:
        return None
    points = []
    for i in range(n):
        point = tuple(values[1 + 3 * i:4 + 3 * i])
        if any(not COORDINATE_MIN <= coordinate <= COORDINATE_MAX
               for coordinate in point):
            return None
        points.append(point)
    return points


def expected_result(values, input_is_null=False, input_length=None):
    points = _parse(values, input_is_null=input_is_null, input_length=input_length)
    if points is None:
        return -1
    checksum = 0
    for i, (x, y, z) in enumerate(points):
        count = sum(
            1 for j, (other_x, other_y, other_z) in enumerate(points)
            if j != i and other_x <= x and other_y <= y and other_z <= z
        )
        checksum += (i + 1) * count
    return checksum
