"""Incremental PMR edge-quadtree reference with exact integer geometry."""
from __future__ import annotations

from collections.abc import Sequence
import struct

MAX_SEGMENTS = 8
MAX_INPUT_LENGTH = 34
MAX_PARSEABLE_INPUT_LENGTH = 35
MAX_DEPTH = 8
MAX_NODES = 2048
MAX_OUTPUT_WORDS = 2 + MAX_NODES * (4 + MAX_SEGMENTS)
MAX_OUTPUT_BYTES = MAX_OUTPUT_WORDS * 8
I64_MIN = -(1 << 63)
I64_MAX = (1 << 63) - 1
INVALID_RESULT = -1
OUTPUT_ERROR = -2
ROOT_BOUNDS = (-1, -1, 511, 511)


class InvalidInput(ValueError):
    """The frame or bounded quadtree construction is invalid."""


class _Node:
    __slots__ = ("parent", "quadrant", "depth", "bounds", "children", "segment_ids")

    def __init__(self, parent: int, quadrant: int, depth: int,
                 bounds: tuple[int, int, int, int]):
        self.parent = parent
        self.quadrant = quadrant
        self.depth = depth
        self.bounds = bounds
        self.children = [-1, -1, -1, -1]
        self.segment_ids: list[int] = []


def _orient(ax: int, ay: int, bx: int, by: int, cx: int, cy: int) -> int:
    return (bx - ax) * (cy - ay) - (by - ay) * (cx - ax)


def _on_segment(ax: int, ay: int, bx: int, by: int, px: int, py: int) -> bool:
    return min(ax, bx) <= px <= max(ax, bx) and min(ay, by) <= py <= max(ay, by)


def _segments_intersect(a: tuple[int, int], b: tuple[int, int],
                        c: tuple[int, int], d: tuple[int, int]) -> bool:
    o1 = _orient(*a, *b, *c)
    o2 = _orient(*a, *b, *d)
    o3 = _orient(*c, *d, *a)
    o4 = _orient(*c, *d, *b)
    if o1 == 0 and _on_segment(*a, *b, *c):
        return True
    if o2 == 0 and _on_segment(*a, *b, *d):
        return True
    if o3 == 0 and _on_segment(*c, *d, *a):
        return True
    if o4 == 0 and _on_segment(*c, *d, *b):
        return True
    return ((o1 < 0 < o2 or o2 < 0 < o1)
            and (o3 < 0 < o4 or o4 < 0 < o3))


def _intersects_box(segment: tuple[int, int, int, int],
                    bounds: tuple[int, int, int, int]) -> bool:
    x0, y0, x1, y1 = (2 * coordinate for coordinate in segment)
    xmin, ymin, xmax, ymax = bounds
    if xmin <= x0 <= xmax and ymin <= y0 <= ymax:
        return True
    if xmin <= x1 <= xmax and ymin <= y1 <= ymax:
        return True
    corners = ((xmin, ymin), (xmax, ymin), (xmax, ymax), (xmin, ymax))
    line = ((x0, y0), (x1, y1))
    return any(_segments_intersect(line[0], line[1], corners[i], corners[(i + 1) % 4])
               for i in range(4))


def _children(bounds: tuple[int, int, int, int]) -> list[tuple[int, int, int, int]]:
    xmin, ymin, xmax, ymax = bounds
    midx = (xmin + xmax) // 2
    midy = (ymin + ymax) // 2
    return [
        (xmin, midy, midx, ymax),  # northwest
        (midx, midy, xmax, ymax),  # northeast
        (xmin, ymin, midx, midy),  # southwest
        (midx, ymin, xmax, midy),  # southeast
    ]


def _parse(values: Sequence[int]) -> tuple[list[tuple[int, int, int, int]], int]:
    if not isinstance(values, (list, tuple)):
        raise InvalidInput("input must be a list or tuple")
    if not 2 <= len(values) <= MAX_PARSEABLE_INPUT_LENGTH:
        raise InvalidInput("input length is outside the parseable range")
    if any(type(value) is not int or not I64_MIN <= value <= I64_MAX for value in values):
        raise InvalidInput("input words must be signed 64-bit integers")
    count, threshold = values[:2]
    if not 0 <= count <= MAX_SEGMENTS or not 1 <= threshold <= MAX_SEGMENTS:
        raise InvalidInput("segment count or splitting threshold is out of range")
    if len(values) != 2 + 4 * count:
        raise InvalidInput("segment frame has the wrong exact length")
    segments = []
    for index in range(count):
        x0, y0, x1, y1 = values[2 + 4 * index: 6 + 4 * index]
        if any(not 0 <= coordinate <= 255 for coordinate in (x0, y0, x1, y1)):
            raise InvalidInput("endpoint coordinate is out of range")
        if x0 == x1 and y0 == y1:
            raise InvalidInput("zero-length segments are excluded")
        segments.append((x0, y0, x1, y1))
    return segments, threshold


def _insert(nodes: list[_Node], segments: list[tuple[int, int, int, int]],
            segment_id: int, node_id: int, threshold: int) -> None:
    node = nodes[node_id]
    if node.children[0] >= 0:
        for child_id in node.children:
            if _intersects_box(segments[segment_id], nodes[child_id].bounds):
                _insert(nodes, segments, segment_id, child_id, threshold)
        return

    node.segment_ids.append(segment_id)
    if len(node.segment_ids) <= threshold:
        return
    if node.depth >= MAX_DEPTH or len(nodes) + 4 > MAX_NODES:
        raise InvalidInput("bounded PMR tree cannot split this overfull cell")

    previous_ids = node.segment_ids[:]
    child_bounds = _children(node.bounds)
    child_ids = []
    for quadrant, bounds in enumerate(child_bounds):
        child_id = len(nodes)
        nodes.append(_Node(node_id, quadrant, node.depth + 1, bounds))
        child_ids.append(child_id)
    node.children[:] = child_ids
    node.segment_ids.clear()
    for old_id in previous_ids:
        for child_id in child_ids:
            if _intersects_box(segments[old_id], nodes[child_id].bounds):
                _insert(nodes, segments, old_id, child_id, threshold)


def _serialize(nodes: list[_Node], segment_count: int) -> bytes:
    order: list[int] = []

    def visit(node_id: int) -> None:
        order.append(node_id)
        for child_id in nodes[node_id].children:
            if child_id >= 0:
                visit(child_id)

    visit(0)
    old_to_new = {old_id: new_id for new_id, old_id in enumerate(order)}
    words = [len(order), segment_count]
    for old_id in order:
        node = nodes[old_id]
        parent = -1 if node.parent < 0 else old_to_new[node.parent]
        words.extend((parent, node.quadrant, node.depth, len(node.segment_ids)))
        words.extend(node.segment_ids)
    return b"".join(struct.pack("<q", word) for word in words)


def _build_output(segments: list[tuple[int, int, int, int]], threshold: int) -> bytes:
    nodes = [_Node(-1, -1, 0, ROOT_BOUNDS)]
    for segment_id in range(len(segments)):
        if not _intersects_box(segments[segment_id], ROOT_BOUNDS):
            raise InvalidInput("segment lies outside the root region")
        _insert(nodes, segments, segment_id, 0, threshold)
    return _serialize(nodes, len(segments))


def expected_output(values: Sequence[int] | None,
                    output_capacity: int | None = MAX_OUTPUT_BYTES,
                    output_is_null: bool = False,
                    input_is_null: bool = False,
                    input_length: int | None = None) -> tuple[int, bytes]:
    """Return canonical preorder PMR nodes encoded as little-endian i64 words."""
    if (type(output_is_null) is not bool or type(input_is_null) is not bool
            or (output_capacity is not None
                and (type(output_capacity) is not int or output_capacity < 0))
            or (input_length is not None
                and (type(input_length) is not int or input_length < 0))):
        return INVALID_RESULT, b""
    if input_is_null or values is None or not isinstance(values, (list, tuple)):
        return INVALID_RESULT, b""
    if input_length is not None and input_length != len(values):
        return INVALID_RESULT, b""
    try:
        segments, threshold = _parse(values)
        encoded = _build_output(segments, threshold)
    except InvalidInput:
        return INVALID_RESULT, b""
    if output_is_null or (output_capacity is not None and output_capacity < len(encoded)):
        return OUTPUT_ERROR, b""
    return len(encoded), encoded
