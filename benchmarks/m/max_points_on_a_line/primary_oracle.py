"""Anchor-and-normalized-direction reference for maximum collinearity."""

from __future__ import annotations

from collections.abc import Sequence
from math import gcd

MAX_N = 16
COORDINATE_LIMIT = 100
MAX_VALID_INPUT_LENGTH = 1 + 2 * MAX_N
MAX_PARSEABLE_INPUT_LENGTH = MAX_VALID_INPUT_LENGTH + 1
INVALID_RESULT = -1


def _decode(values: Sequence[int] | None, input_length: int | None) -> list[tuple[int, int]] | None:
    if not isinstance(values, (list, tuple)):
        return None
    if input_length is not None and (type(input_length) is not int or input_length != len(values)):
        return None
    if len(values) < 3 or len(values) > MAX_PARSEABLE_INPUT_LENGTH:
        return None
    if any(type(value) is not int or not -(1 << 63) <= value < (1 << 63) for value in values):
        return None
    n = values[0]
    if not 1 <= n <= MAX_N or len(values) != 1 + 2 * n:
        return None
    points = [(values[1 + 2 * i], values[2 + 2 * i]) for i in range(n)]
    if any(abs(x) > COORDINATE_LIMIT or abs(y) > COORDINATE_LIMIT for x, y in points):
        return None
    if len(set(points)) != n:
        return None
    return points


def expected_result(values: Sequence[int] | None, input_length: int | None = None) -> int:
    points = _decode(values, input_length)
    if points is None:
        return INVALID_RESULT
    n = len(points)
    if n == 1:
        return 1
    answer = 1
    for anchor, (x0, y0) in enumerate(points):
        directions: dict[tuple[int, int], int] = {}
        for other, (x1, y1) in enumerate(points):
            if other == anchor:
                continue
            dx = x1 - x0
            dy = y1 - y0
            divisor = gcd(abs(dx), abs(dy))
            dx //= divisor
            dy //= divisor
            if dx < 0 or (dx == 0 and dy < 0):
                dx = -dx
                dy = -dy
            direction = (dx, dy)
            directions[direction] = directions.get(direction, 0) + 1
        if directions:
            answer = max(answer, 1 + max(directions.values()))
    return answer


def expected_output(values: Sequence[int] | None, input_length: int | None = None) -> int:
    return expected_result(values, input_length)
