"""Exhaustive exact triangulation oracle for max-min edge length."""

from __future__ import annotations

from collections.abc import Sequence
from functools import lru_cache
from itertools import combinations

MIN_VERTICES = 3
MAX_VERTICES = 6
COORDINATE_LIMIT = 8
MAX_PARSEABLE_INPUT_LENGTH = 14
INVALID_RESULT = -1
Point = tuple[int, int]
Triangle = tuple[int, int, int]


def _orientation(a: Point, b: Point, c: Point) -> int:
    return (b[0] - a[0]) * (c[1] - a[1]) - (b[1] - a[1]) * (c[0] - a[0])


def _parse(values: Sequence[int] | None, input_is_null: bool,
           input_length: int | None) -> tuple[Point, ...] | None:
    if (type(input_is_null) is not bool or input_is_null
            or not isinstance(values, (list, tuple))
            or not 1 <= len(values) <= MAX_PARSEABLE_INPUT_LENGTH
            or any(type(word) is not int or not -(1 << 63) <= word < (1 << 63)
                   for word in values)):
        return None
    if input_length is None:
        input_length = len(values)
    if type(input_length) is not int or input_length != len(values):
        return None
    n = values[0]
    if not MIN_VERTICES <= n <= MAX_VERTICES or input_length != 1 + 2 * n:
        return None
    points = tuple((values[1 + 2*i], values[2 + 2*i]) for i in range(n))
    if any(max(abs(x), abs(y)) > COORDINATE_LIMIT for x, y in points):
        return None
    if len(set(points)) != n:
        return None
    area2 = sum(points[i][0] * points[(i + 1) % n][1]
                - points[i][1] * points[(i + 1) % n][0] for i in range(n))
    if area2 <= 0:
        return None
    if any(_orientation(points[a], points[b], points[c]) == 0
           for a, b, c in combinations(range(n), 3)):
        return None
    for edge in range(n):
        following = (edge + 1) % n
        if any(_orientation(points[edge], points[following], points[v]) <= 0
               for v in range(n) if v not in (edge, following)):
            return None
    return points


def _length_squared(a: Point, b: Point) -> int:
    return (a[0] - b[0]) ** 2 + (a[1] - b[1]) ** 2


def _diagonal_bit(n: int, a: int, b: int) -> int:
    left, right = sorted((a, b))
    bit = 0
    for first in range(n):
        for second in range(first + 2, n):
            if first == 0 and second == n - 1:
                continue
            if (first, second) == (left, right):
                return bit
            bit += 1
    return -1


def _greedy_signature(points: tuple[Point, ...]) -> int:
    """Recreate the deterministic corner choices using list deletion."""
    n = len(points)
    active = list(range(n))
    p, q, r = active[0], active[1], active[2]
    mask = 0
    while len(active) > 3:
        u = (points[p][0] - points[q][0], points[p][1] - points[q][1])
        v = (points[r][0] - points[q][0], points[r][1] - points[q][1])
        dot = u[0] * v[0] + u[1] * v[1]
        cut = dot <= 0 or 4 * dot * dot <= (u[0] ** 2 + u[1] ** 2) * (v[0] ** 2 + v[1] ** 2)
        q_position = active.index(q)
        if cut:
            bit = _diagonal_bit(n, p, r)
            if bit < 0:
                return -1
            mask |= 1 << bit
            active.pop(q_position)
            q = r
            r = active[(active.index(r) + 1) % len(active)]
        else:
            p = q
            q = r
            r = active[(active.index(r) + 1) % len(active)]
    return mask


def _all_triangulation_scores(points: tuple[Point, ...]) -> tuple[tuple[int, int], ...]:
    n = len(points)

    @lru_cache(maxsize=None)
    def enumerate_triangulations(left: int, right: int) -> tuple[tuple[Triangle, ...], ...]:
        if right - left < 2:
            return ((),)
        results: list[tuple[Triangle, ...]] = []
        for split in range(left + 1, right):
            root = (left, split, right)
            for before in enumerate_triangulations(left, split):
                for after in enumerate_triangulations(split, right):
                    results.append((root,) + before + after)
        return tuple(results)

    hull_edges: set[tuple[int, int]] = set()
    for i in range(n):
        following = (i + 1) % n
        hull_edges.add((i, following) if i < following else (following, i))
    outcomes: list[tuple[int, int]] = []
    for triangles in enumerate_triangulations(0, n - 1):
        edges = set(hull_edges)
        for a, b, c in triangles:
            edges.add((a, b) if a < b else (b, a))
            edges.add((b, c) if b < c else (c, b))
            edges.add((a, c) if a < c else (c, a))
        score = min(_length_squared(points[a], points[b]) for a, b in edges)
        mask = 0
        for a, b in edges:
            bit = _diagonal_bit(n, a, b)
            if bit >= 0:
                mask |= 1 << bit
        outcomes.append((score, mask))
    return tuple(outcomes)


def expected_result(values: Sequence[int] | None, input_is_null: bool = False,
                    input_length: int | None = None) -> int:
    points = _parse(values, input_is_null, input_length)
    if points is None:
        return INVALID_RESULT
    triangulations = _all_triangulation_scores(points)
    optimum = max(score for score, _mask in triangulations)
    mask = _greedy_signature(points)
    assert mask >= 0 and (optimum, mask) in triangulations
    return optimum * 512 + mask


def verify_candidate(values: Sequence[int] | None, result: int,
                     input_is_null: bool = False,
                     input_length: int | None = None) -> bool:
    """Exhaustively check that a packed mask is a triangulation attaining optimum."""
    points = _parse(values, input_is_null, input_length)
    if points is None:
        return type(result) is int and result == INVALID_RESULT
    if type(result) is not int or result < 0:
        return False
    objective, mask = divmod(result, 512)
    outcomes = _all_triangulation_scores(points)
    optimum = max(score for score, _signature in outcomes)
    deterministic_mask = _greedy_signature(points)
    return (objective == optimum and mask == deterministic_mask
            and (objective, mask) in outcomes)
