"""Primary exact oracle for a supplied Kirkpatrick hierarchy query."""

from __future__ import annotations

import struct
from collections.abc import Sequence

MAX_VERTICES = 16
MAX_LEVELS = 4
MAX_FACES = 8
MAX_INPUT = 268
MAX_OUTPUT_BYTES = 16


def _cross(a: tuple[int, int], b: tuple[int, int], c: tuple[int, int]) -> int:
    return (b[0] - a[0]) * (c[1] - a[1]) - (b[1] - a[1]) * (c[0] - a[0])


def _on_segment(a: tuple[int, int], b: tuple[int, int], p: tuple[int, int]) -> bool:
    return (_cross(a, b, p) == 0 and min(a[0], b[0]) <= p[0] <= max(a[0], b[0])
            and min(a[1], b[1]) <= p[1] <= max(a[1], b[1]))


def _inside(point: tuple[int, int], tri: tuple[int, int, int], points: list[tuple[int, int]]) -> bool:
    a, b, c = (points[index] for index in tri)
    return _cross(a, b, point) > 0 and _cross(b, c, point) > 0 and _cross(c, a, point) > 0


def _on_boundary(point: tuple[int, int], tri: tuple[int, int, int],
                 points: list[tuple[int, int]]) -> bool:
    a, b, c = (points[index] for index in tri)
    return _on_segment(a, b, point) or _on_segment(b, c, point) or _on_segment(c, a, point)


def _segments_intersect(a: tuple[int, int], b: tuple[int, int],
                        c: tuple[int, int], d: tuple[int, int]) -> bool:
    ab_c, ab_d = _cross(a, b, c), _cross(a, b, d)
    cd_a, cd_b = _cross(c, d, a), _cross(c, d, b)
    if ab_c == 0 and _on_segment(a, b, c):
        return True
    if ab_d == 0 and _on_segment(a, b, d):
        return True
    if cd_a == 0 and _on_segment(c, d, a):
        return True
    if cd_b == 0 and _on_segment(c, d, b):
        return True
    return (ab_c < 0) != (ab_d < 0) and (cd_a < 0) != (cd_b < 0)


def _intersects(first: tuple[int, int, int], second: tuple[int, int, int],
                points: list[tuple[int, int]]) -> bool:
    a = [points[index] for index in first]
    b = [points[index] for index in second]
    for p in a:
        if all(_cross(b[i], b[(i + 1) % 3], p) >= 0 for i in range(3)):
            return True
    for p in b:
        if all(_cross(a[i], a[(i + 1) % 3], p) >= 0 for i in range(3)):
            return True
    return any(_segments_intersect(a[i], a[(i + 1) % 3], b[j], b[(j + 1) % 3])
               for i in range(3) for j in range(3))


def _parse(values: Sequence[int] | None):
    if (not isinstance(values, (list, tuple)) or not 14 <= len(values) <= MAX_INPUT
            or any(type(value) is not int or not -(1 << 63) <= value < (1 << 63)
                   for value in values)):
        return None
    vertices, level_count, qx, qy = values[:4]
    if not 3 <= vertices <= MAX_VERTICES or not 1 <= level_count <= MAX_LEVELS:
        return None
    if not -1000 <= qx <= 1000 or not -1000 <= qy <= 1000:
        return None
    position = 4
    points = []
    for _ in range(vertices):
        x, y = values[position:position + 2]
        position += 2
        if not -1000 <= x <= 1000 or not -1000 <= y <= 1000:
            return None
        points.append((x, y))
    query = (qx, qy)
    levels: list[list[tuple[int, int, int]]] = []
    candidates: list[list[list[int]]] = []
    for level in range(level_count):
        if position >= len(values):
            return None
        face_count = values[position]
        position += 1
        if not 1 <= face_count <= MAX_FACES or level == 0 and face_count != 1:
            return None
        faces = []
        for _ in range(face_count):
            if position + 3 > len(values):
                return None
            face = tuple(values[position:position + 3])
            position += 3
            if (len(set(face)) != 3 or any(index < 0 or index >= vertices for index in face)
                    or _cross(*(points[index] for index in face)) <= 0):
                return None
            faces.append(face)
        levels.append(faces)
        if level + 1 < level_count:
            transition = []
            next_count = None
            for _ in range(face_count):
                if position >= len(values):
                    return None
                candidate_count = values[position]
                position += 1
                if not 1 <= candidate_count <= MAX_FACES or position + candidate_count > len(values):
                    return None
                ids = list(values[position:position + candidate_count])
                position += candidate_count
                if (any(index < 0 or index >= MAX_FACES for index in ids)
                        or ids != sorted(set(ids))):
                    return None
                transition.append(ids)
            candidates.append(transition)
    if position != len(values):
        return None
    for level, transition in enumerate(candidates):
        for face_id, ids in enumerate(transition):
            for child_id in ids:
                if child_id >= len(levels[level + 1]) or not _intersects(
                        levels[level][face_id], levels[level + 1][child_id], points):
                    return None
    if any(_on_boundary(query, face, points) for faces in levels for face in faces):
        return None
    for faces in levels:
        if sum(_inside(query, face, points) for face in faces) != 1:
            return None
    return points, query, levels, candidates


def _locate(parsed) -> tuple[int, int] | None:
    points, query, levels, candidates = parsed
    face_id = 0
    predicates = 1  # test the single top-level triangle
    for level, transition in enumerate(candidates):
        found = None
        for child_id in transition[face_id]:
            predicates += 1
            if _inside(query, levels[level + 1][child_id], points):
                found = child_id
                break
        if found is None:
            return None
        face_id = found
    return face_id, predicates


def expected_output(values: Sequence[int] | None, capacity: int | None = None,
                    output_is_null: bool = False, input_is_null: bool = False,
                    input_length: int | None = None) -> tuple[int, bytes]:
    if (type(output_is_null) is not bool or type(input_is_null) is not bool
            or capacity is not None and (type(capacity) is not int or capacity < 0)
            or input_length is not None and (type(input_length) is not int
                                             or not 0 <= input_length <= MAX_INPUT)
            or input_is_null and values not in (None, [], ())
            or not input_is_null and values is not None and input_length is not None
            and input_length != len(values)):
        return -1, b""
    if input_is_null or values is None:
        return -1, b""
    parsed = _parse(values)
    if parsed is None:
        return -1, b""
    located = _locate(parsed)
    if located is None:
        return -1, b""
    payload = struct.pack("<2q", *located)
    if output_is_null or capacity is not None and capacity < len(payload):
        return -2, b""
    return len(payload), payload
