"""Independent cell-enumeration reference using rational segment clipping."""
from __future__ import annotations

from collections.abc import Sequence
from fractions import Fraction
import struct

try:
    from .primary_oracle import (
        I64_MAX, I64_MIN, INVALID_RESULT, MAX_DEPTH, MAX_OUTPUT_BYTES,
        MAX_PARSEABLE_INPUT_LENGTH, OUTPUT_ERROR,
    )
except ImportError:
    from primary_oracle import (
        I64_MAX, I64_MIN, INVALID_RESULT, MAX_DEPTH, MAX_OUTPUT_BYTES,
        MAX_PARSEABLE_INPUT_LENGTH, OUTPUT_ERROR,
    )


class InvalidInput(ValueError):
    """The canonical bounded triangulation frame is malformed."""


def _parse_frame(values: Sequence[int]) -> tuple[list[tuple[int, int]], list[tuple[int, int, int]]]:
    if len(values) < 2 or len(values) > MAX_PARSEABLE_INPUT_LENGTH:
        raise InvalidInput("frame length is outside the parseable range")
    vertex_count, triangle_count = values[:2]
    if not ((vertex_count == 4 and triangle_count == 2)
            or (vertex_count == 5 and triangle_count == 4)):
        raise InvalidInput("unsupported bounded triangulation size")
    if len(values) != 2 + 2 * vertex_count + 3 * triangle_count:
        raise InvalidInput("frame length differs from its declared topology")
    coordinates = tuple(values[2:2 + 2 * vertex_count])
    if coordinates[:8] != (0, 0, 8, 0, 8, 8, 0, 8):
        raise InvalidInput("square vertices are not in canonical order")
    if vertex_count == 5 and coordinates[8:] != (4, 4):
        raise InvalidInput("fifth vertex must be the square center")
    raw_triangles = tuple(values[2 + 2 * vertex_count:])
    valid = ((0, 1, 2, 0, 2, 3), (0, 1, 3, 1, 2, 3)) if vertex_count == 4 else (
        (0, 1, 4, 1, 2, 4, 2, 3, 4, 3, 0, 4),)
    if raw_triangles not in valid:
        raise InvalidInput("triangle sequence is not a canonical square triangulation")
    vertices = [(coordinates[2 * i], coordinates[2 * i + 1]) for i in range(vertex_count)]
    triangles = [tuple(raw_triangles[3 * i:3 * i + 3]) for i in range(triangle_count)]
    return vertices, triangles


def _clip_segment_to_box(a: tuple[int, int], b: tuple[int, int],
                         box: tuple[int, int, int, int]) -> bool:
    xmin, ymin, xmax, ymax = box
    enter, leave = Fraction(0), Fraction(1)
    for origin, delta, lower, upper in (
            (a[0], b[0] - a[0], xmin, xmax),
            (a[1], b[1] - a[1], ymin, ymax)):
        if delta == 0:
            if origin < lower or origin > upper:
                return False
            continue
        t0, t1 = Fraction(lower - origin, delta), Fraction(upper - origin, delta)
        enter = max(enter, min(t0, t1))
        leave = min(leave, max(t0, t1))
        if enter > leave:
            return False
    return True


def _point_in_ccw_triangle(point: tuple[int, int], a: tuple[int, int],
                           b: tuple[int, int], c: tuple[int, int]) -> bool:
    def cross(p: tuple[int, int], q: tuple[int, int], r: tuple[int, int]) -> int:
        return (q[0] - p[0]) * (r[1] - p[1]) - (q[1] - p[1]) * (r[0] - p[0])
    return cross(a, b, point) >= 0 and cross(b, c, point) >= 0 and cross(c, a, point) >= 0


def _box_at(depth: int, ix: int, iy: int) -> tuple[int, int, int, int]:
    size = 8 >> depth
    xmin = ix * size
    xmax = xmin + size
    ymax = 8 - iy * size
    return xmin, ymax - size, xmax, ymax


def _edge_set(triangles: list[tuple[int, int, int]]) -> list[tuple[int, int]]:
    edges = {(min(a, b), max(a, b))
             for tri in triangles
             for a, b in ((tri[0], tri[1]), (tri[1], tri[2]), (tri[2], tri[0]))}
    return sorted(edges)


def _cell_edge_list(vertices: list[tuple[int, int]], edges: list[tuple[int, int]],
                    box: tuple[int, int, int, int]) -> list[tuple[int, int]]:
    xmin, ymin, xmax, ymax = box
    touched = []
    for edge in edges:
        a, b = vertices[edge[0]], vertices[edge[1]]
        if (xmin <= a[0] <= xmax and ymin <= a[1] <= ymax
                or xmin <= b[0] <= xmax and ymin <= b[1] <= ymax
                or _clip_segment_to_box(a, b, box)):
            touched.append(edge)
    return touched


def _is_stopping_cell(vertices: list[tuple[int, int]], edges: list[tuple[int, int]],
                      box: tuple[int, int, int, int]) -> bool:
    touched = _cell_edge_list(vertices, edges, box)
    if not touched:
        return True
    return any(all(vertex in edge for edge in touched) for vertex in range(len(vertices)))


def _triangle_touches_box(triangle: tuple[int, int, int],
                          vertices: list[tuple[int, int]],
                          box: tuple[int, int, int, int]) -> bool:
    xmin, ymin, xmax, ymax = box
    points = [vertices[index] for index in triangle]
    if any(xmin <= x <= xmax and ymin <= y <= ymax for x, y in points):
        return True
    corners = ((xmin, ymin), (xmax, ymin), (xmax, ymax), (xmin, ymax))
    if any(_point_in_ccw_triangle(p, points[0], points[1], points[2]) for p in corners):
        return True
    return any(_clip_segment_to_box(points[i], points[(i + 1) % 3], box)
               for i in range(3))


def _morton_start(depth: int, ix: int, iy: int) -> int:
    scale = 1 << (MAX_DEPTH - depth)
    x, y = ix * scale, iy * scale
    value = 0
    for bit in range(MAX_DEPTH - 1, -1, -1):
        value = (value << 1) | ((y >> bit) & 1)
        value = (value << 1) | ((x >> bit) & 1)
    return value


def _all_leaf_pairs(vertices: list[tuple[int, int]],
                    triangles: list[tuple[int, int, int]]) -> list[int]:
    edges = _edge_set(triangles)
    stopping: dict[tuple[int, int, int], bool] = {}
    for depth in range(MAX_DEPTH + 1):
        side = 1 << depth
        for iy in range(side):
            for ix in range(side):
                stopping[(depth, ix, iy)] = _is_stopping_cell(
                    vertices, edges, _box_at(depth, ix, iy))

    pairs: list[tuple[int, int]] = []
    for depth in range(MAX_DEPTH + 1):
        side = 1 << depth
        for iy in range(side):
            for ix in range(side):
                if not stopping[(depth, ix, iy)]:
                    if depth == MAX_DEPTH:
                        raise InvalidInput("bounded Star quadtree exceeds its depth cap")
                    continue
                if depth > 0 and stopping[(depth - 1, ix // 2, iy // 2)]:
                    continue
                box = _box_at(depth, ix, iy)
                z = _morton_start(depth, ix, iy)
                for triangle_id, triangle in enumerate(triangles):
                    if _triangle_touches_box(triangle, vertices, box):
                        pairs.append((z, triangle_id))
    pairs.sort()
    words = [len(pairs)]
    for z, triangle_id in pairs:
        words.extend((z, triangle_id))
    return words


def expected_output(values: Sequence[int] | None,
                    capacity: int | None = MAX_OUTPUT_BYTES,
                    output_is_null: bool = False,
                    input_is_null: bool = False,
                    input_length: int | None = None) -> tuple[int, bytes]:
    if (type(output_is_null) is not bool or type(input_is_null) is not bool
            or (capacity is not None and (type(capacity) is not int or capacity < 0))
            or (input_length is not None and (type(input_length) is not int or input_length < 0))):
        return INVALID_RESULT, b""
    if input_is_null or values is None or not isinstance(values, (list, tuple)):
        return INVALID_RESULT, b""
    if input_length is not None and input_length != len(values):
        return INVALID_RESULT, b""
    if not 2 <= len(values) <= MAX_PARSEABLE_INPUT_LENGTH:
        return INVALID_RESULT, b""
    if any(type(value) is not int or not I64_MIN <= value <= I64_MAX for value in values):
        return INVALID_RESULT, b""
    try:
        vertices, triangles = _parse_frame(values)
        words = _all_leaf_pairs(vertices, triangles)
    except InvalidInput:
        return INVALID_RESULT, b""
    encoded = b"".join(struct.pack("<q", word) for word in words)
    if output_is_null or (capacity is not None and capacity < len(encoded)):
        return OUTPUT_ERROR, b""
    return len(encoded), encoded
