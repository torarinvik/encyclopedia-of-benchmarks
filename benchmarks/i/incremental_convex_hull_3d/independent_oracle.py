"""Independent supporting-plane enumeration oracle for 3D hull volume."""

from __future__ import annotations

from collections.abc import Sequence
from itertools import combinations

from .primary_oracle import (
    INVALID_RESULT,
    MAX_COORDINATE,
    MAX_N,
    MAX_PARSEABLE_INPUT_LENGTH,
    _cross,
    _dot,
    _det_origin,
    _orient,
    _sub,
)


def _decode(values: Sequence[int] | None, input_is_null: bool,
            input_length: int | None) -> list[tuple[int, int, int]] | None:
    if (type(input_is_null) is not bool or input_is_null
            or not isinstance(values, (list, tuple))
            or len(values) < 1 or len(values) > MAX_PARSEABLE_INPUT_LENGTH
            or any(type(value) is not int or not -(1 << 63) <= value < (1 << 63)
                   for value in values)):
        return None
    if input_length is not None and (
            type(input_length) is not int or input_length != len(values)):
        return None
    n = values[0]
    if not 4 <= n <= MAX_N or len(values) != 1 + 3 * n:
        return None
    points = [tuple(values[1 + 3 * i:4 + 3 * i]) for i in range(n)]
    if any(any(not -MAX_COORDINATE <= coordinate <= MAX_COORDINATE
               for coordinate in point) for point in points):
        return None
    if len(set(points)) != n:
        return None
    for i, j, k, ell in combinations(range(n), 4):
        if _orient(points[i], points[j], points[k], points[ell]) == 0:
            return None
    return points


def expected_result(values: Sequence[int] | None, input_is_null: bool = False,
                    input_length: int | None = None) -> int:
    points = _decode(values, input_is_null, input_length)
    if points is None:
        return INVALID_RESULT

    volume_six = 0
    for i, j, k in combinations(range(len(points)), 3):
        normal = _cross(_sub(points[j], points[i]), _sub(points[k], points[i]))
        positive_side = False
        negative_side = False
        for other in range(len(points)):
            if other in (i, j, k):
                continue
            side = _dot(normal, _sub(points[other], points[i]))
            positive_side |= side > 0
            negative_side |= side < 0
        if positive_side and negative_side:
            continue
        if positive_side:
            volume_six += _det_origin(points[i], points[k], points[j])
        else:
            volume_six += _det_origin(points[i], points[j], points[k])
    return volume_six
