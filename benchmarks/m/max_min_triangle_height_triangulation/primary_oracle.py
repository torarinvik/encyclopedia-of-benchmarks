"""Bounded edge-insertion reference for max-min triangle height."""

from __future__ import annotations

from collections.abc import Sequence
from fractions import Fraction
from math import gcd

MIN_VERTICES = 3
MAX_VERTICES = 5
COORDINATE_LIMIT = 8
MAX_VALID_INPUT_LENGTH = 1 + 2 * MAX_VERTICES
MAX_PARSEABLE_INPUT_LENGTH = MAX_VALID_INPUT_LENGTH + 1
MAX_OUTPUT = 262_144 * 513 + 512
MAX_IMPROVEMENTS = 30
INVALID_RESULT = -1

Point = tuple[int, int]
Triangle = tuple[int, int, int]
Objective = tuple[Fraction, int]


def _cross(a: Point, b: Point, c: Point) -> int:
    return (b[0] - a[0]) * (c[1] - a[1]) - (b[1] - a[1]) * (c[0] - a[0])


def _parse(values: Sequence[int] | None, input_is_null: bool,
           input_length: int | None) -> tuple[Point, ...] | None:
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
    if not MIN_VERTICES <= n <= MAX_VERTICES or len(values) != 1 + 2 * n:
        return None
    points = tuple((values[1 + 2 * i], values[2 + 2 * i]) for i in range(n))
    if any(abs(x) > COORDINATE_LIMIT or abs(y) > COORDINATE_LIMIT for x, y in points):
        return None
    if len(set(points)) != n:
        return None
    if sum(points[i][0] * points[(i + 1) % n][1]
           - points[i][1] * points[(i + 1) % n][0] for i in range(n)) <= 0:
        return None
    for a in range(n):
        for b in range(a + 1, n):
            for c in range(b + 1, n):
                if _cross(points[a], points[b], points[c]) == 0:
                    return None
    for edge in range(n):
        following = (edge + 1) % n
        for vertex in range(n):
            if vertex not in (edge, following) and _cross(
                    points[edge], points[following], points[vertex]) <= 0:
                return None
    return points


def _triangle_score(points: tuple[Point, ...], a: int, b: int, c: int) -> Fraction:
    n = len(points)
    pa, pb, pc = points[a % n], points[b % n], points[c % n]
    area2 = abs(_cross(pa, pb, pc))
    lengths = (
        (pa[0] - pb[0]) ** 2 + (pa[1] - pb[1]) ** 2,
        (pb[0] - pc[0]) ** 2 + (pb[1] - pc[1]) ** 2,
        (pc[0] - pa[0]) ** 2 + (pc[1] - pa[1]) ** 2,
    )
    return min(Fraction(area2 * area2, length) for length in lengths)


def _join(left: Objective | None, right: Objective | None,
          triangle: Fraction) -> Objective:
    minimum = triangle
    count = 1
    for child in (left, right):
        if child is None:
            continue
        if child[0] < minimum:
            minimum, count = child
        elif child[0] == minimum:
            count += child[1]
    return minimum, count


def _better(candidate: Objective, current: Objective) -> bool:
    return candidate[0] > current[0] or (
        candidate[0] == current[0] and candidate[1] < current[1]
    )


def _objective(points: tuple[Point, ...], triangles: list[Triangle]) -> Objective:
    scores = [_triangle_score(points, *triangle) for triangle in triangles]
    minimum = min(scores)
    return minimum, scores.count(minimum)


def _edge_present(triangles: list[Triangle], left: int, right: int) -> bool:
    wanted = (left, right)
    return any(tuple(sorted(pair)) == wanted
               for a, b, c in triangles
               for pair in ((a, b), (b, c), (c, a)))


def _collect(start: int, end: int, splits: list[list[int]], n: int,
             output: list[Triangle]) -> None:
    if end - start < 2:
        return
    middle = splits[start][end]
    output.append((start % n, middle % n, end % n))
    _collect(start, middle, splits, n, output)
    _collect(middle, end, splits, n, output)


def _edge_insertion(points: tuple[Point, ...]) -> Objective | None:
    n = len(points)
    size = 2 * n
    table: list[list[Objective | None]] = [[None] * size for _ in range(size)]
    splits = [[-1] * size for _ in range(size)]

    # These tables optimally retriangulate every proper cyclic subpolygon.
    for span in range(2, n - 1):
        for start in range(n):
            end = start + span
            best: Objective | None = None
            best_middle = -1
            for middle in range(start + 1, end):
                candidate = _join(
                    table[start][middle], table[middle][end],
                    _triangle_score(points, start, middle, end),
                )
                if best is None or _better(candidate, best):
                    best, best_middle = candidate, middle
            table[start][end] = best
            splits[start][end] = best_middle

    # Begin with a deterministic fan, then insert the first diagonal whose
    # optimal retriangulation improves (minimum height, worst-triangle count).
    current: list[Triangle] = [(0, k, k + 1) for k in range(1, n - 1)]
    current_objective = _objective(points, current)
    improvements = 0
    while True:
        changed = False
        for left in range(n):
            for right in range(left + 2, n):
                if left == 0 and right == n - 1:
                    continue
                if _edge_present(current, left, right):
                    continue
                candidate_triangles: list[Triangle] = []
                _collect(left, right, splits, n, candidate_triangles)
                _collect(right, left + n, splits, n, candidate_triangles)
                candidate_objective = _objective(points, candidate_triangles)
                if _better(candidate_objective, current_objective):
                    current, current_objective = candidate_triangles, candidate_objective
                    improvements += 1
                    if improvements > MAX_IMPROVEMENTS:
                        return None
                    changed = True
                    break
            if changed:
                break
        if not changed:
            return current_objective


def expected_result(values: Sequence[int] | None, input_is_null: bool = False,
                    input_length: int | None = None) -> int:
    points = _parse(values, input_is_null, input_length)
    if points is None:
        return INVALID_RESULT
    objective = _edge_insertion(points)
    if objective is None:
        return INVALID_RESULT
    minimum, _worst_count = objective
    return minimum.numerator * 513 + minimum.denominator
