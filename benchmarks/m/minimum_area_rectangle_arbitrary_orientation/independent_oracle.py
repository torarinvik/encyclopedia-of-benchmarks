"""Exhaustive four-point and cyclic-order geometry reference."""

from __future__ import annotations

from collections.abc import Sequence
from itertools import combinations, permutations

from .primary_oracle import (
    INVALID_RESULT,
    _points,
)


def expected_result(values: Sequence[int] | None, input_is_null: bool = False,
                    input_length: int | None = None) -> int:
    points = _points(values, input_is_null, input_length)
    if points is None:
        return INVALID_RESULT
    best: int | None = None
    for subset in combinations(points, 4):
        for p, q, r, s in permutations(subset):
            # Opposite vertices share a midpoint; adjacent sides meet at 90°.
            if p[0] + r[0] != q[0] + s[0] or p[1] + r[1] != q[1] + s[1]:
                continue
            ux, uy = q[0] - p[0], q[1] - p[1]
            vx, vy = s[0] - p[0], s[1] - p[1]
            if ux * vx + uy * vy != 0:
                continue
            doubled_area = 2 * abs(ux * vy - uy * vx)
            if best is None or doubled_area < best:
                best = doubled_area
    return 0 if best is None else best
