"""Pair-defined exact-line reference using integer cross products."""

from __future__ import annotations

from collections.abc import Sequence

from .primary_oracle import (
    COORDINATE_LIMIT,
    INVALID_RESULT,
    MAX_N,
    MAX_PARSEABLE_INPUT_LENGTH,
)


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
    answer = 2
    for first in range(n):
        x0, y0 = points[first]
        for second in range(first + 1, n):
            x1, y1 = points[second]
            dx = x1 - x0
            dy = y1 - y0
            count = 0
            for x, y in points:
                if dx * (y - y0) == dy * (x - x0):
                    count += 1
            answer = max(answer, count)
    return answer


def expected_output(values: Sequence[int] | None, input_length: int | None = None) -> int:
    return expected_result(values, input_length)
