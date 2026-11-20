"""Bounded primary reference for min-max triangle eccentricity edge insertion."""

from __future__ import annotations

from collections.abc import Sequence
from itertools import combinations
from math import gcd

MIN_VERTICES = 3
MAX_VERTICES = 6
COORDINATE_LIMIT = 4
MAX_VALID_INPUT_LENGTH = 1 + 2 * MAX_VERTICES
MAX_PARSEABLE_INPUT_LENGTH = MAX_VALID_INPUT_LENGTH + 1
MAX_TRIANGULATIONS = 14
INVALID_RESULT = -1

Point = tuple[int, int]
Triangle = tuple[int, int, int]
Fraction = tuple[int, int]


def _cross(points: tuple[Point, ...], a: int, b: int, c: int) -> int:
    ax, ay = points[a]
    bx, by = points[b]
    cx, cy = points[c]
    return (bx - ax) * (cy - ay) - (by - ay) * (cx - ax)


def _strictly_convex(points: tuple[Point, ...]) -> bool:
    n = len(points)
    area2 = sum(points[i][0] * points[(i + 1) % n][1]
                - points[i][1] * points[(i + 1) % n][0] for i in range(n))
    if area2 == 0:
        return False
    orientation = 1 if area2 > 0 else -1
    if any(_cross(points, a, b, c) == 0 for a, b, c in combinations(range(n), 3)):
        return False
    for edge in range(n):
        following = (edge + 1) % n
        for vertex in range(n):
            if vertex not in (edge, following) and orientation * _cross(
                    points, edge, following, vertex) <= 0:
                return False
    return True


def _parse(values: Sequence[int] | None, input_is_null: bool,
           input_length: int | None) -> tuple[Point, ...] | None:
    if (type(input_is_null) is not bool or input_is_null
            or not isinstance(values, (list, tuple))):
        return None
    if input_length is None:
        input_length = len(values)
    if (type(input_length) is not int or input_length < 1
            or input_length > MAX_PARSEABLE_INPUT_LENGTH or input_length != len(values)):
        return None
    if any(type(value) is not int or not -(1 << 63) <= value < (1 << 63)
           for value in values):
        return None
    n = values[0]
    if not MIN_VERTICES <= n <= MAX_VERTICES or input_length != 1 + 2 * n:
        return None
    points = tuple((values[1 + 2 * i], values[2 + 2 * i]) for i in range(n))
    if any(abs(x) > COORDINATE_LIMIT or abs(y) > COORDINATE_LIMIT for x, y in points):
        return None
    return points if _strictly_convex(points) else None


def _fraction(num: int, den: int) -> Fraction:
    divisor = gcd(num, den)
    return num // divisor, den // divisor


def _compare(a: Fraction, b: Fraction) -> int:
    left, right = a[0] * b[1], b[0] * a[1]
    return -1 if left < right else 1 if left > right else 0


def _side_squares(points: tuple[Point, ...], triangle: Triangle) -> tuple[int, int, int]:
    a, b, c = triangle
    pa, pb, pc = points[a], points[b], points[c]
    return (
        (pb[0] - pc[0]) ** 2 + (pb[1] - pc[1]) ** 2,
        (pc[0] - pa[0]) ** 2 + (pc[1] - pa[1]) ** 2,
        (pa[0] - pb[0]) ** 2 + (pa[1] - pb[1]) ** 2,
    )


def _triangle_score(points: tuple[Point, ...], triangle: Triangle) -> Fraction:
    sides = _side_squares(points, triangle)
    largest = max(sides)
    if largest <= sum(sides) - largest:
        return 0, 1
    area2 = abs(_cross(points, *triangle))
    difference = largest - (sum(sides) - largest)
    return _fraction(largest * difference * difference, 16 * area2 * area2)


def _triangle_id(triangle: Triangle, n: int) -> int:
    wanted = tuple(sorted(triangle))
    index = 0
    for a, b, c in combinations(range(n), 3):
        if (a, b, c) == wanted:
            return index
        index += 1
    raise ValueError("triangle is outside the input vertex set")


def _edge_bit(a: int, b: int) -> int:
    low, high = sorted((a, b))
    return 1 << (low * MAX_VERTICES + high)


def _boundary_edge(a: int, b: int, n: int) -> bool:
    low, high = sorted((a, b))
    return high == low + 1 or (low == 0 and high == n - 1)


def _edge_mask(triangles: tuple[Triangle, ...], n: int) -> int:
    result = 0
    for a, b, c in triangles:
        result |= _edge_bit(a, b) | _edge_bit(b, c) | _edge_bit(c, a)
    # Boundary edges are part of every triangulation, including the triangle case.
    for a in range(n):
        result |= _edge_bit(a, (a + 1) % n)
    return result


def _inside_triangle(points: tuple[Point, ...], triangle: Triangle, vertex: int) -> bool:
    a, b, c = triangle
    direction = _cross(points, a, b, c)
    return all(_cross(points, x, y, vertex) * direction > 0
               for x, y in ((a, b), (b, c), (c, a)))


def _properly_crosses(points: tuple[Point, ...], a: int, b: int, c: int, d: int) -> bool:
    return (_cross(points, a, b, c) * _cross(points, a, b, d) < 0
            and _cross(points, c, d, a) * _cross(points, c, d, b) < 0)


def _all_triangulations(points: tuple[Point, ...]) -> tuple[tuple[Triangle, ...], ...]:
    n = len(points)
    diagonals = [(a, b) for a in range(n) for b in range(a + 2, n)
                 if not (a == 0 and b == n - 1)]
    result: list[tuple[Triangle, ...]] = []
    for selected in range(1 << len(diagonals)):
        if selected.bit_count() != n - 3:
            continue
        chosen = [diagonals[i] for i in range(len(diagonals)) if selected >> i & 1]
        if any(_properly_crosses(points, *chosen[i], *chosen[j])
               for i in range(len(chosen)) for j in range(i + 1, len(chosen))):
            continue
        edges = _edge_mask(tuple(), n)
        for a, b in chosen:
            edges |= _edge_bit(a, b)
        faces: list[Triangle] = []
        for a, b, c in combinations(range(n), 3):
            if not all(edges & _edge_bit(x, y) for x, y in ((a, b), (b, c), (c, a))):
                continue
            if any(_inside_triangle(points, (a, b, c), v)
                   for v in range(n) if v not in (a, b, c)):
                continue
            faces.append((a, b, c))
        if len(faces) == n - 2:
            result.append(tuple(faces))
    return tuple(result)


def _metrics(points: tuple[Point, ...], triangles: tuple[Triangle, ...]) -> tuple[Fraction, int]:
    maximum: Fraction = (0, 1)
    worst = 0
    for triangle in triangles:
        score = _triangle_score(points, triangle)
        comparison = _compare(score, maximum)
        bit = 1 << _triangle_id(triangle, len(points))
        if comparison > 0:
            maximum, worst = score, bit
        elif comparison == 0:
            worst |= bit
    return maximum, worst


def _improves(candidate: tuple[Fraction, int], current: tuple[Fraction, int]) -> bool:
    comparison = _compare(candidate[0], current[0])
    if comparison < 0:
        return True
    return (comparison == 0 and candidate[1] != current[1]
            and candidate[1] & current[1] == candidate[1])


def _popcount(value: int) -> int:
    return value.bit_count()


def _primary(points: tuple[Point, ...]) -> Fraction:
    n = len(points)
    all_triangulations = _all_triangulations(points)
    fan = tuple((0, middle, middle + 1) for middle in range(1, n - 1))
    current = next(triangles for triangles in all_triangulations
                   if _edge_mask(triangles, n) == _edge_mask(fan, n))
    current_metrics = _metrics(points, current)

    # Every accepted move strictly descends in a finite set of at most 14 states.
    for _ in range(MAX_TRIANGULATIONS):
        changed = False
        current_edges = _edge_mask(current, n)
        for triangle in current:
            score = _triangle_score(points, triangle)
            if _compare(score, current_metrics[0]) != 0 or score[0] == 0:
                continue
            a, b, c = triangle
            vertices = (a, b, c)
            sides = _side_squares(points, triangle)
            largest_side = max(sides)
            for anchor_position, q in enumerate(vertices):
                if sides[anchor_position] != largest_side:
                    continue
                opposite = tuple(vertex for vertex in vertices if vertex != q)
                for s in range(n):
                    new_edge = _edge_bit(q, s)
                    if s == q or current_edges & new_edge:
                        continue
                    if not _properly_crosses(points, q, s, *opposite):
                        continue
                    retained = current_edges
                    for u in range(n):
                        for v in range(u + 1, n):
                            bit = _edge_bit(u, v)
                            if (retained & bit and _properly_crosses(points, q, s, u, v)):
                                retained &= ~bit

                    selected: tuple[tuple[Triangle, ...], tuple[Fraction, int]] | None = None
                    for candidate in all_triangulations:
                        candidate_edges = _edge_mask(candidate, n)
                        if not candidate_edges & new_edge or candidate_edges & retained != retained:
                            continue
                        candidate_metrics = _metrics(points, candidate)
                        if not _improves(candidate_metrics, current_metrics):
                            continue
                        if selected is None:
                            selected = candidate, candidate_metrics
                            continue
                        cmp = _compare(candidate_metrics[0], selected[1][0])
                        if (cmp < 0 or (cmp == 0 and
                                (_popcount(candidate_metrics[1]) < _popcount(selected[1][1])
                                 or (_popcount(candidate_metrics[1]) == _popcount(selected[1][1])
                                     and candidate_metrics[1] < selected[1][1])))):
                            selected = candidate, candidate_metrics
                    if selected is not None:
                        current, current_metrics = selected
                        changed = True
                        break
                if changed:
                    break
            if changed:
                break
        if not changed:
            return current_metrics[0]
    return current_metrics[0]


def _rank(points: tuple[Point, ...], target: Fraction) -> int:
    distinct_lower: list[Fraction] = []
    for triangle in combinations(range(len(points)), 3):
        score = _triangle_score(points, triangle)
        if _compare(score, target) >= 0:
            continue
        if not any(_compare(score, previous) == 0 for previous in distinct_lower):
            distinct_lower.append(score)
    return len(distinct_lower) + 1


def expected_result(values: Sequence[int] | None, input_is_null: bool = False,
                    input_length: int | None = None) -> int:
    points = _parse(values, input_is_null, input_length)
    if points is None:
        return INVALID_RESULT
    return _rank(points, _primary(points))
