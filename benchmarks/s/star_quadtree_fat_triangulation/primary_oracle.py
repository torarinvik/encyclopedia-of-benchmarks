"""Bounded direct-construction reference for a Star quadtree."""
from __future__ import annotations

from collections.abc import Sequence
import struct

MAX_VERTICES = 5
MAX_TRIANGLES = 4
MAX_DEPTH = 2
MAX_LEAVES = 16
MAX_PAIRS = MAX_LEAVES * MAX_TRIANGLES
MAX_OUTPUT_WORDS = 1 + 2 * MAX_PAIRS
MAX_OUTPUT_BYTES = MAX_OUTPUT_WORDS * 8
MAX_INPUT_LENGTH = 24
MAX_PARSEABLE_INPUT_LENGTH = 25
WORKSPACE_BYTES = 8192
INVALID_RESULT = -1
OUTPUT_ERROR = -2
I64_MIN = -(1 << 63)
I64_MAX = (1 << 63) - 1

_SQUARE = (0, 0, 8, 0, 8, 8, 0, 8)
_DIAGONAL_02 = (0, 1, 2, 0, 2, 3)
_DIAGONAL_13 = (0, 1, 3, 1, 2, 3)
_CENTER_FAN = (0, 1, 4, 1, 2, 4, 2, 3, 4, 3, 0, 4)


class InvalidInput(ValueError):
    """The bounded triangulation frame is malformed."""


def _parse(values: Sequence[int]) -> tuple[list[tuple[int, int]], list[tuple[int, int, int]]]:
    if not isinstance(values, (list, tuple)) or not 2 <= len(values) <= MAX_PARSEABLE_INPUT_LENGTH:
        raise InvalidInput("frame length is outside the parseable range")
    if any(type(value) is not int or not I64_MIN <= value <= I64_MAX for value in values):
        raise InvalidInput("input words must be signed 64-bit integers")
    vertex_count, triangle_count = values[:2]
    if vertex_count == 4 and triangle_count == 2:
        expected_triangles = (tuple(_DIAGONAL_02), tuple(_DIAGONAL_13))
    elif vertex_count == 5 and triangle_count == 4:
        expected_triangles = (tuple(_CENTER_FAN),)
    else:
        raise InvalidInput("only the bounded square triangulations are accepted")
    if len(values) != 2 + 2 * vertex_count + 3 * triangle_count:
        raise InvalidInput("frame has the wrong exact length")
    coords = tuple(values[2:2 + 2 * vertex_count])
    if vertex_count == 4:
        if coords != _SQUARE:
            raise InvalidInput("square corners must use the canonical vertex order")
    elif coords != _SQUARE + (4, 4):
        raise InvalidInput("the optional fifth vertex must be the square center")
    raw_triangles = tuple(values[2 + 2 * vertex_count:])
    if raw_triangles not in expected_triangles:
        raise InvalidInput("triangle sequence is not one of the canonical fat triangulations")
    vertices = [(coords[2 * i], coords[2 * i + 1]) for i in range(vertex_count)]
    triangles = [tuple(raw_triangles[3 * i:3 * i + 3]) for i in range(triangle_count)]
    return vertices, triangles


def _orientation(a: tuple[int, int], b: tuple[int, int], c: tuple[int, int]) -> int:
    return (b[0] - a[0]) * (c[1] - a[1]) - (b[1] - a[1]) * (c[0] - a[0])


def _on_segment(a: tuple[int, int], b: tuple[int, int], p: tuple[int, int]) -> bool:
    return (min(a[0], b[0]) <= p[0] <= max(a[0], b[0])
            and min(a[1], b[1]) <= p[1] <= max(a[1], b[1]))


def _segments_intersect(a: tuple[int, int], b: tuple[int, int],
                        c: tuple[int, int], d: tuple[int, int]) -> bool:
    o1 = _orientation(a, b, c)
    o2 = _orientation(a, b, d)
    o3 = _orientation(c, d, a)
    o4 = _orientation(c, d, b)
    if o1 == 0 and _on_segment(a, b, c):
        return True
    if o2 == 0 and _on_segment(a, b, d):
        return True
    if o3 == 0 and _on_segment(c, d, a):
        return True
    if o4 == 0 and _on_segment(c, d, b):
        return True
    return ((o1 < 0 < o2 or o2 < 0 < o1)
            and (o3 < 0 < o4 or o4 < 0 < o3))


def _edges(triangles: list[tuple[int, int, int]]) -> list[tuple[int, int]]:
    result: list[tuple[int, int]] = []
    for triangle in triangles:
        for a, b in ((triangle[0], triangle[1]), (triangle[1], triangle[2]),
                     (triangle[2], triangle[0])):
            edge = (min(a, b), max(a, b))
            if edge not in result:
                result.append(edge)
    return result


def _edge_hits_box(edge: tuple[int, int], vertices: list[tuple[int, int]],
                   box: tuple[int, int, int, int]) -> bool:
    ax, ay = vertices[edge[0]]
    bx, by = vertices[edge[1]]
    xmin, ymin, xmax, ymax = box
    if xmin <= ax <= xmax and ymin <= ay <= ymax:
        return True
    if xmin <= bx <= xmax and ymin <= by <= ymax:
        return True
    corners = ((xmin, ymin), (xmax, ymin), (xmax, ymax), (xmin, ymax))
    return any(_segments_intersect((ax, ay), (bx, by), corners[i], corners[(i + 1) % 4])
               for i in range(4))


def _stop_cell(vertices: list[tuple[int, int]], edges: list[tuple[int, int]],
               box: tuple[int, int, int, int]) -> bool:
    intersected = [edge for edge in edges if _edge_hits_box(edge, vertices, box)]
    if not intersected:
        return True
    return any(all(vertex in edge for edge in intersected)
               for vertex in range(len(vertices)))


def _point_in_triangle(p: tuple[int, int], a: tuple[int, int],
                       b: tuple[int, int], c: tuple[int, int]) -> bool:
    return (_orientation(a, b, p) >= 0 and _orientation(b, c, p) >= 0
            and _orientation(c, a, p) >= 0)


def _triangle_hits_box(triangle: tuple[int, int, int],
                       vertices: list[tuple[int, int]],
                       box: tuple[int, int, int, int]) -> bool:
    xmin, ymin, xmax, ymax = box
    points = [vertices[index] for index in triangle]
    if any(xmin <= x <= xmax and ymin <= y <= ymax for x, y in points):
        return True
    corners = ((xmin, ymin), (xmax, ymin), (xmax, ymax), (xmin, ymax))
    if any(_point_in_triangle(point, points[0], points[1], points[2]) for point in corners):
        return True
    for i in range(3):
        a, b = points[i], points[(i + 1) % 3]
        if _edge_hits_box((triangle[i], triangle[(i + 1) % 3]), vertices, box):
            return True
    return False


def _z_key(path_code: int, depth: int) -> int:
    return path_code << (2 * (MAX_DEPTH - depth))


def _construct(vertices: list[tuple[int, int]],
               triangles: list[tuple[int, int, int]]) -> list[int]:
    edges = _edges(triangles)
    pairs: list[tuple[int, int]] = []

    def visit(depth: int, ix: int, iy: int, path_code: int) -> None:
        size = 8 >> depth
        xmin = ix * size
        xmax = xmin + size
        ymax = 8 - iy * size
        ymin = ymax - size
        box = (xmin, ymin, xmax, ymax)
        if not _stop_cell(vertices, edges, box):
            if depth >= MAX_DEPTH:
                raise InvalidInput("bounded Star quadtree exceeds its depth cap")
            for quadrant in range(4):
                child_x = ix * 2 + (quadrant & 1)
                child_y = iy * 2 + (quadrant >> 1)
                visit(depth + 1, child_x, child_y, path_code * 4 + quadrant)
            return
        key = _z_key(path_code, depth)
        for triangle_id, triangle in enumerate(triangles):
            if _triangle_hits_box(triangle, vertices, box):
                pairs.append((key, triangle_id))

    visit(0, 0, 0, 0)
    pairs.sort()
    if len(pairs) > MAX_PAIRS:
        raise InvalidInput("bounded cell-triangle output limit exceeded")
    words = [len(pairs)]
    for key, triangle_id in pairs:
        words.extend((key, triangle_id))
    return words


def expected_output(values: Sequence[int] | None,
                    capacity: int | None = MAX_OUTPUT_BYTES,
                    output_is_null: bool = False,
                    input_is_null: bool = False,
                    input_length: int | None = None) -> tuple[int, bytes]:
    """Build a bounded Star quadtree and emit sorted (Z key, triangle) pairs."""
    if (type(output_is_null) is not bool or type(input_is_null) is not bool
            or (capacity is not None and (type(capacity) is not int or capacity < 0))
            or (input_length is not None and (type(input_length) is not int or input_length < 0))):
        return INVALID_RESULT, b""
    if input_is_null or values is None or not isinstance(values, (list, tuple)):
        return INVALID_RESULT, b""
    if input_length is not None and input_length != len(values):
        return INVALID_RESULT, b""
    try:
        vertices, triangles = _parse(values)
        words = _construct(vertices, triangles)
    except InvalidInput:
        return INVALID_RESULT, b""
    encoded = b"".join(struct.pack("<q", word) for word in words)
    if output_is_null or (capacity is not None and capacity < len(encoded)):
        return OUTPUT_ERROR, b""
    return len(encoded), encoded
