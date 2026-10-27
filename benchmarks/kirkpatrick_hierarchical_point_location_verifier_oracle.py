"""Independent area/SAT verifier for the supplied Kirkpatrick query hierarchy."""

from __future__ import annotations

import struct
from collections.abc import Sequence

MAX_VERTICES = 16
MAX_LEVELS = 4
MAX_FACES = 8
MAX_INPUT = 268


def _area(a: tuple[int, int], b: tuple[int, int], c: tuple[int, int]) -> int:
    return (b[0] - a[0]) * (c[1] - a[1]) - (b[1] - a[1]) * (c[0] - a[0])


def _areas(p: tuple[int, int], tri: tuple[int, int, int], points):
    a, b, c = (points[i] for i in tri)
    return _area(a, b, c), _area(a, p, c), _area(a, b, p), _area(p, b, c)


def _strict(p: tuple[int, int], tri: tuple[int, int, int], points) -> bool:
    whole, one, two, three = _areas(p, tri, points)
    return whole > 0 and one > 0 and two > 0 and three > 0 and one + two + three == whole


def _boundary(p: tuple[int, int], tri: tuple[int, int, int], points) -> bool:
    for k in range(3):
        a = points[tri[k]]
        b = points[tri[(k + 1) % 3]]
        if (_area(a, b, p) == 0 and min(a[0], b[0]) <= p[0] <= max(a[0], b[0])
                and min(a[1], b[1]) <= p[1] <= max(a[1], b[1])):
            return True
    return False


def _separated(axis_a: tuple[int, int], axis_b: tuple[int, int],
               first, second, points) -> bool:
    dx = axis_b[0] - axis_a[0]
    dy = axis_b[1] - axis_a[1]
    nx, ny = -dy, dx
    first_projection = [points[i][0] * nx + points[i][1] * ny for i in first]
    second_projection = [points[i][0] * nx + points[i][1] * ny for i in second]
    return max(first_projection) < min(second_projection) or max(second_projection) < min(first_projection)


def _overlap(first, second, points) -> bool:
    # Separating-axis check is independent of the primary oracle's edge/vertex tests.
    for tri_a, tri_b in ((first, second), (second, first)):
        for k in range(3):
            if _separated(points[tri_a[k]], points[tri_a[(k + 1) % 3]], first, second, points):
                return False
    return True


def _decode(values: Sequence[int] | None):
    if (not isinstance(values, (list, tuple)) or not 14 <= len(values) <= MAX_INPUT
            or any(type(v) is not int or not -(1 << 63) <= v < (1 << 63) for v in values)):
        return None
    vertex_count, depth, qx, qy = values[0:4]
    if vertex_count not in range(3, MAX_VERTICES + 1) or depth not in range(1, MAX_LEVELS + 1):
        return None
    if qx not in range(-1000, 1001) or qy not in range(-1000, 1001):
        return None
    at = 4
    vertices = []
    for _ in range(vertex_count):
        x, y = values[at], values[at + 1]
        at += 2
        if x not in range(-1000, 1001) or y not in range(-1000, 1001):
            return None
        vertices.append((x, y))
    query = (qx, qy)
    meshes = []
    links = []
    for layer in range(depth):
        if at == len(values):
            return None
        count = values[at]
        at += 1
        if count not in range(1, MAX_FACES + 1) or layer == 0 and count != 1:
            return None
        triangles = []
        for _ in range(count):
            if at + 3 > len(values):
                return None
            triangle = tuple(values[at:at + 3])
            at += 3
            if (len(set(triangle)) != 3 or any(i < 0 or i >= vertex_count for i in triangle)
                    or _area(*(vertices[i] for i in triangle)) <= 0):
                return None
            triangles.append(triangle)
        meshes.append(triangles)
        if layer < depth - 1:
            layer_links = []
            for _ in triangles:
                if at == len(values):
                    return None
                size = values[at]
                at += 1
                if size not in range(1, MAX_FACES + 1) or at + size > len(values):
                    return None
                child_ids = list(values[at:at + size])
                at += size
                if (any(i < 0 or i >= MAX_FACES for i in child_ids)
                        or any(child_ids[i] >= child_ids[i + 1] for i in range(len(child_ids) - 1))):
                    return None
                layer_links.append(child_ids)
            links.append(layer_links)
    if at != len(values):
        return None
    for level, parent_links in enumerate(links):
        for parent_id, child_ids in enumerate(parent_links):
            for child_id in child_ids:
                if child_id >= len(meshes[level + 1]) or not _overlap(
                        meshes[level][parent_id], meshes[level + 1][child_id], vertices):
                    return None
    for triangles in meshes:
        if any(_boundary(query, tri, vertices) for tri in triangles):
            return None
        if sum(1 for tri in triangles if _strict(query, tri, vertices)) != 1:
            return None
    return query, vertices, meshes, links


def _answer(decoded):
    query, vertices, meshes, links = decoded
    face = 0
    tests = 1
    for level, face_links in enumerate(links):
        selected = None
        for child in face_links[face]:
            tests += 1
            if _strict(query, meshes[level + 1][child], vertices):
                selected = child
                break
        if selected is None:
            return None
        face = selected
    return face, tests


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
    decoded = _decode(values)
    if decoded is None:
        return -1, b""
    answer = _answer(decoded)
    if answer is None:
        return -1, b""
    payload = struct.pack("<2q", *answer)
    if output_is_null or capacity is not None and capacity < len(payload):
        return -2, b""
    return len(payload), payload
