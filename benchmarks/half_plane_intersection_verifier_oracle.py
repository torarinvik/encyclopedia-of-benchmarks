"""Independent pair-intersection and exact convex-hull verifier."""

from __future__ import annotations

import math
from collections.abc import Sequence
from fractions import Fraction

from half_plane_intersection_oracle import (
    BOX,
    MAX_OUTPUT_BYTES,
    WORKSPACE_BYTES,
    _encode,
    _parse,
)


def _enumerated_hull(constraints: Sequence[tuple[int, int, int]]) -> list[tuple[int, int, int]]:
    lines = list(constraints) + [(1, 0, BOX), (0, 1, BOX), (-1, 0, BOX), (0, -1, BOX)]
    points: set[tuple[Fraction, Fraction]] = set()
    for i, (a, b, c) in enumerate(lines):
        for d, e, f in lines[i + 1:]:
            det = a * e - d * b
            if det == 0:
                continue
            x = Fraction(c * e - b * f, det)
            y = Fraction(a * f - c * d, det)
            if all(u * x + v * y <= w for u, v, w in lines):
                points.add((x, y))
    if len(points) < 3:
        return []
    ordered = sorted(points)

    def turn(p: tuple[Fraction, Fraction], q: tuple[Fraction, Fraction],
             r: tuple[Fraction, Fraction]) -> Fraction:
        return ((q[0] - p[0]) * (r[1] - p[1])
                - (q[1] - p[1]) * (r[0] - p[0]))

    lower: list[tuple[Fraction, Fraction]] = []
    for point in ordered:
        while len(lower) >= 2 and turn(lower[-2], lower[-1], point) <= 0:
            lower.pop()
        lower.append(point)
    upper: list[tuple[Fraction, Fraction]] = []
    for point in reversed(ordered):
        while len(upper) >= 2 and turn(upper[-2], upper[-1], point) <= 0:
            upper.pop()
        upper.append(point)
    hull = lower[:-1] + upper[:-1]
    if len(hull) < 3:
        return []
    first = min(range(len(hull)), key=lambda i: (hull[i][1], hull[i][0]))
    hull = hull[first:] + hull[:first]
    result: list[tuple[int, int, int]] = []
    for x, y in hull:
        den = math.lcm(x.denominator, y.denominator)
        xn = x.numerator * (den // x.denominator)
        yn = y.numerator * (den // y.denominator)
        common = math.gcd(math.gcd(abs(xn), abs(yn)), den)
        result.append((xn // common, yn // common, den // common))
    return result


def verify_output(values: Sequence[int] | None, result: int, output: bytes,
                  capacity: int | None = None, output_is_null: bool = False,
                  input_is_null: bool = False, input_length: int | None = None) -> bool:
    return expected_output(values, capacity, output_is_null, input_is_null, input_length) == (result, output)


def expected_output(values: Sequence[int] | None, capacity: int | None = None,
                    output_is_null: bool = False, input_is_null: bool = False,
                    input_length: int | None = None) -> tuple[int, bytes]:
    constraints = _parse(values, input_length, input_is_null)
    if constraints is None:
        return -1, b""
    expected = _encode(_enumerated_hull(constraints))
    effective_capacity = MAX_OUTPUT_BYTES if capacity is None else capacity
    if type(output_is_null) is not bool or type(effective_capacity) is not int or effective_capacity < 0:
        return -2, b""
    if output_is_null or len(expected) > effective_capacity:
        return -2, b""
    return len(expected), expected
