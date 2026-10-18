"""Oracle for the bounded Java point-quadtree insertion and range-query trace."""

from __future__ import annotations

from collections.abc import Sequence
import struct

MAX_POINTS = 64
MAX_VALID_INPUT_LENGTH = 8 + 2 * MAX_POINTS
MAX_PARSEABLE_INPUT_LENGTH = MAX_VALID_INPUT_LENGTH + 1
MAX_OUTPUT_WORDS = 2 + 3 * MAX_POINTS
MAX_OUTPUT_BYTES = MAX_OUTPUT_WORDS * 8
I64_MIN = -(1 << 63)
I64_MAX = (1 << 63) - 1
INVALID_RESULT = -1
OUTPUT_ERROR = -2


class InvalidInput(ValueError):
    """Raised when a trace falls outside the bounded quadtree contract."""


class _Node:
    def __init__(self, cx: float, cy: float, half_width: float, capacity: int):
        self.cx = cx
        self.cy = cy
        self.half_width = half_width
        self.capacity = capacity
        self.points: list[tuple[int, int]] = []
        self.children: list[_Node] | None = None

    def contains(self, point: tuple[int, int]) -> bool:
        x, y = point
        return (
            x >= self.cx - self.half_width
            and x <= self.cx + self.half_width
            and y >= self.cy - self.half_width
            and y <= self.cy + self.half_width
        )

    def subdivide(self) -> None:
        child_half = self.half_width / 2.0
        # This order matches QuadTree.insert and QuadTree.query.
        self.children = [
            _Node(self.cx - child_half, self.cy + child_half, child_half, self.capacity),
            _Node(self.cx + child_half, self.cy + child_half, child_half, self.capacity),
            _Node(self.cx - child_half, self.cy - child_half, child_half, self.capacity),
            _Node(self.cx + child_half, self.cy - child_half, child_half, self.capacity),
        ]

    def insert(self, point: tuple[int, int]) -> bool:
        if not self.contains(point):
            return False
        if len(self.points) < self.capacity:
            self.points.append(point)
            return True
        if self.children is None:
            self.subdivide()
        assert self.children is not None
        for child in self.children:
            if child.insert(point):
                return True
        return False

    def query(self, cx: float, cy: float, half_width: float) -> list[tuple[int, int]]:
        if (
            cx - half_width > self.cx + self.half_width
            or cx + half_width < self.cx - self.half_width
            or cy - half_width > self.cy + self.half_width
            or cy + half_width < self.cy - self.half_width
        ):
            return []
        result = [
            point
            for point in self.points
            if point[0] >= cx - half_width
            and point[0] <= cx + half_width
            and point[1] >= cy - half_width
            and point[1] <= cy + half_width
        ]
        if self.children is not None:
            for child in self.children:
                result.extend(child.query(cx, cy, half_width))
        return result


def _parse(values: Sequence[int]) -> tuple[_Node, list[tuple[int, int]], tuple[int, int, int]]:
    if not isinstance(values, (list, tuple)):
        raise InvalidInput("input must be a list or tuple")
    if not 8 <= len(values) <= MAX_PARSEABLE_INPUT_LENGTH:
        raise InvalidInput("input length is outside the parseable range")
    if any(type(value) is not int or not I64_MIN <= value <= I64_MAX for value in values):
        raise InvalidInput("input words must be signed 64-bit integers")

    root_cx, root_cy, root_half, capacity, count = values[:5]
    if not -2048 <= root_cx <= 2048 or not -2048 <= root_cy <= 2048:
        raise InvalidInput("root center is outside the supported range")
    if not 1 <= root_half <= 1024 or not 1 <= capacity <= 8:
        raise InvalidInput("root half-width or node capacity is outside the supported range")
    if not 0 <= count <= MAX_POINTS or len(values) != 8 + 2 * count:
        raise InvalidInput("point count or framing is invalid")

    points: list[tuple[int, int]] = []
    seen: set[tuple[int, int]] = set()
    point_offset = 5
    for index in range(count):
        x = values[point_offset + 2 * index]
        y = values[point_offset + 2 * index + 1]
        if not -8192 <= x <= 8192 or not -8192 <= y <= 8192:
            raise InvalidInput("point coordinate is outside the supported range")
        point = (x, y)
        if point in seen:
            raise InvalidInput("duplicate points are excluded to bound subdivision")
        seen.add(point)
        points.append(point)

    query_offset = point_offset + 2 * count
    query_cx, query_cy, query_half = values[query_offset : query_offset + 3]
    if not -8192 <= query_cx <= 8192 or not -8192 <= query_cy <= 8192:
        raise InvalidInput("query center is outside the supported range")
    if not 0 <= query_half <= 8192:
        raise InvalidInput("query half-width is outside the supported range")
    root = _Node(float(root_cx), float(root_cy), float(root_half), capacity)
    return root, points, (query_cx, query_cy, query_half)


def expected_output(
    values: Sequence[int] | None,
    output_capacity: int | None = MAX_OUTPUT_BYTES,
    output_is_null: bool = False,
    input_is_null: bool = False,
    input_length: int | None = None,
) -> tuple[int, bytes]:
    """Return source-ordered insert flags and range-query points as LE i64 bytes."""
    if type(output_is_null) is not bool or type(input_is_null) is not bool:
        return INVALID_RESULT, b""
    if output_capacity is not None and (
        type(output_capacity) is not int or output_capacity < 0
    ):
        return INVALID_RESULT, b""
    if input_length is not None and (
        type(input_length) is not int or input_length < 0
    ):
        return INVALID_RESULT, b""
    if input_is_null or values is None or not isinstance(values, (list, tuple)):
        return INVALID_RESULT, b""
    if input_length is not None and input_length != len(values):
        return INVALID_RESULT, b""
    try:
        root, points, query = _parse(values)
    except InvalidInput:
        return INVALID_RESULT, b""

    flags = [1 if root.insert(point) else 0 for point in points]
    query_points = root.query(float(query[0]), float(query[1]), float(query[2]))
    words = [len(flags), *flags, len(query_points)]
    for x, y in query_points:
        words.extend((x, y))
    encoded = b"".join(struct.pack("<q", word) for word in words)
    if output_is_null or (output_capacity is not None and output_capacity < len(encoded)):
        return OUTPUT_ERROR, b""
    return len(encoded), encoded
