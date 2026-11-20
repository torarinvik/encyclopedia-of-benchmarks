"""Bounded incremental 3D convex hull and exact six-volume oracle."""

from __future__ import annotations

from collections.abc import Sequence
from itertools import combinations

MAX_N = 6
MAX_COORDINATE = 10
MAX_VALID_INPUT_LENGTH = 1 + 3 * MAX_N
MAX_PARSEABLE_INPUT_LENGTH = MAX_VALID_INPUT_LENGTH + 1
INVALID_RESULT = -1

Point = tuple[int, int, int]
Face = tuple[int, int, int]


def _cross(left: Point, right: Point) -> Point:
    return (
        left[1] * right[2] - left[2] * right[1],
        left[2] * right[0] - left[0] * right[2],
        left[0] * right[1] - left[1] * right[0],
    )


def _dot(left: Point, right: Point) -> int:
    return left[0] * right[0] + left[1] * right[1] + left[2] * right[2]


def _sub(left: Point, right: Point) -> Point:
    return left[0] - right[0], left[1] - right[1], left[2] - right[2]


def _orient(a: Point, b: Point, c: Point, point: Point) -> int:
    return _dot(_cross(_sub(b, a), _sub(c, a)), _sub(point, a))


def _det_origin(a: Point, b: Point, c: Point) -> int:
    return _dot(a, _cross(b, c))


def _decode(values: Sequence[int] | None, input_is_null: bool,
            input_length: int | None) -> list[Point] | None:
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
    points: list[Point] = []
    for index in range(n):
        point = tuple(values[1 + 3 * index:4 + 3 * index])
        if any(not -MAX_COORDINATE <= coordinate <= MAX_COORDINATE
               for coordinate in point):
            return None
        points.append(point)  # type: ignore[arg-type]
    if len(set(points)) != n:
        return None
    # General position: every four points span a nonzero-volume tetrahedron.
    for i, j, k, ell in combinations(range(n), 4):
        if _orient(points[i], points[j], points[k], points[ell]) == 0:
            return None
    return points


def _outward_face(a: int, b: int, c: int, points: list[Point],
                  interior_sum: Point) -> Face:
    origin = points[a]
    normal = _cross(_sub(points[b], origin), _sub(points[c], origin))
    center_offset = (
        interior_sum[0] - 4 * origin[0],
        interior_sum[1] - 4 * origin[1],
        interior_sum[2] - 4 * origin[2],
    )
    # The initial tetrahedron's centroid stays strictly inside every later hull.
    if _dot(normal, center_offset) > 0:
        return a, c, b
    return a, b, c


def expected_result(values: Sequence[int] | None, input_is_null: bool = False,
                    input_length: int | None = None) -> int:
    points = _decode(values, input_is_null, input_length)
    if points is None:
        return INVALID_RESULT

    interior_sum: Point = tuple(
        sum(points[index][axis] for index in range(4)) for axis in range(3)
    )  # four times the centroid of the initial tetrahedron
    faces: list[Face] = [
        _outward_face(0, 1, 2, points, interior_sum),
        _outward_face(0, 3, 1, points, interior_sum),
        _outward_face(0, 2, 3, points, interior_sum),
        _outward_face(1, 3, 2, points, interior_sum),
    ]

    for point_index in range(4, len(points)):
        visible = [
            _orient(points[a], points[b], points[c], points[point_index]) > 0
            for a, b, c in faces
        ]
        if not any(visible):
            continue

        horizon_edges: list[tuple[int, int]] = []
        visible_edges = [
            (edge_a, edge_b)
            for face, is_visible in zip(faces, visible)
            if is_visible
            for edge_a, edge_b in ((face[0], face[1]), (face[1], face[2]),
                                   (face[2], face[0]))
        ]
        for edge_index, (edge_a, edge_b) in enumerate(visible_edges):
            copies = sum(
                1 for other_index, (other_a, other_b) in enumerate(visible_edges)
                if other_index != edge_index
                and ((edge_a == other_a and edge_b == other_b)
                     or (edge_a == other_b and edge_b == other_a))
            )
            if copies == 0:
                horizon_edges.append((edge_a, edge_b))

        updated = [face for face, is_visible in zip(faces, visible) if not is_visible]
        for edge_a, edge_b in horizon_edges:
            updated.append(_outward_face(edge_a, edge_b, point_index,
                                         points, interior_sum))
        faces = updated

    return sum(_det_origin(points[a], points[b], points[c]) for a, b, c in faces)
