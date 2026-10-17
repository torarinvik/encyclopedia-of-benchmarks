"""Oracle for the bounded two-dimensional KD-tree workload."""

from __future__ import annotations

from dataclasses import dataclass
from collections.abc import Sequence

MAX_INITIAL_POINTS = 64
MAX_POINTS = 128
MAX_OPERATIONS = 256
MIN_COORDINATE = -1_000
MAX_COORDINATE = 1_000
MAX_VALID_INPUT_VALUES = 898
MAX_PARSEABLE_INPUT_VALUES = 899
INVALID_RESULT = -1
I64_MIN = -(1 << 63)
I64_MAX = (1 << 63) - 1
CHECKSUM_OFFSET = 1_001


@dataclass
class _Node:
    point: tuple[int, int]
    axis: int
    left: _Node | None = None
    right: _Node | None = None


def _build(points: list[tuple[int, int]], depth: int = 0) -> _Node | None:
    if not points:
        return None
    axis = depth % 2
    ordered = sorted(points, key=lambda point: point[axis])
    median = len(ordered) >> 1
    return _Node(
        point=ordered[median],
        axis=axis,
        left=_build(ordered[:median], depth + 1),
        right=_build(ordered[median + 1 :], depth + 1),
    )


def _insert(node: _Node | None, point: tuple[int, int], depth: int = 0) -> _Node:
    if node is None:
        return _Node(point=point, axis=depth % 2)
    if point[node.axis] < node.point[node.axis]:
        node.left = _insert(node.left, point, depth + 1)
    else:
        node.right = _insert(node.right, point, depth + 1)
    return node


def _search(node: _Node | None, point: tuple[int, int]) -> bool:
    if node is None:
        return False
    if node.point == point:
        return True
    child = node.left if point[node.axis] < node.point[node.axis] else node.right
    return _search(child, point)


def _points(node: _Node | None):
    if node is None:
        return
    yield node.point
    yield from _points(node.left)
    yield from _points(node.right)


def _distance_squared(left: tuple[int, int], right: tuple[int, int]) -> int:
    dx = left[0] - right[0]
    dy = left[1] - right[1]
    return dx * dx + dy * dy


def _find_nearest(
    node: _Node | None,
    query: tuple[int, int],
    nearest: _Node,
) -> _Node:
    """Mirror the pinned source traversal, including its far-branch test."""
    if node is None:
        return nearest
    if node.point == query:
        return node

    distance = _distance_squared(node.point, query)
    distance_except_axis = sum(
        (node.point[axis] - query[axis]) ** 2
        for axis in range(2)
        if axis != node.axis
    )
    if distance < _distance_squared(nearest.point, query):
        nearest = node

    query_goes_left = query[node.axis] < node.point[node.axis]
    near = node.left if query_goes_left else node.right
    far = node.right if query_goes_left else node.left
    nearest = _find_nearest(near, query, nearest)
    if distance_except_axis < _distance_squared(nearest.point, query):
        nearest = _find_nearest(far, query, nearest)
    return nearest


def expected_result(values: Sequence[int] | None) -> int:
    """Return the KD-tree trace checksum, or -1 for a malformed trace."""
    if (
        not isinstance(values, (list, tuple))
        or len(values) > MAX_PARSEABLE_INPUT_VALUES
        or len(values) < 2
        or any(
            type(value) is not int or not I64_MIN <= value <= I64_MAX
            for value in values
        )
    ):
        return INVALID_RESULT

    initial_count = values[0]
    if not 0 <= initial_count <= MAX_INITIAL_POINTS:
        return INVALID_RESULT
    cursor = 1
    if cursor + 2 * initial_count + 1 > len(values):
        return INVALID_RESULT

    initial_points: list[tuple[int, int]] = []
    seen_x: set[int] = set()
    seen_y: set[int] = set()
    for _ in range(initial_count):
        x, y = values[cursor : cursor + 2]
        cursor += 2
        if not MIN_COORDINATE <= x <= MAX_COORDINATE:
            return INVALID_RESULT
        if not MIN_COORDINATE <= y <= MAX_COORDINATE:
            return INVALID_RESULT
        if x in seen_x or y in seen_y:
            return INVALID_RESULT
        seen_x.add(x)
        seen_y.add(y)
        initial_points.append((x, y))

    operation_count = values[cursor]
    cursor += 1
    if not 0 <= operation_count <= MAX_OPERATIONS:
        return INVALID_RESULT
    if cursor + 3 * operation_count > len(values):
        return INVALID_RESULT

    root = _build(initial_points)
    point_count = initial_count
    checksum = 0
    for operation_index in range(operation_count):
        opcode, first, second = values[cursor : cursor + 3]
        cursor += 3

        if opcode in (0, 1, 4):
            if not MIN_COORDINATE <= first <= MAX_COORDINATE:
                return INVALID_RESULT
            if not MIN_COORDINATE <= second <= MAX_COORDINATE:
                return INVALID_RESULT
            point = (first, second)
            if opcode == 0:
                if point_count >= MAX_POINTS or first in seen_x or second in seen_y:
                    return INVALID_RESULT
                seen_x.add(first)
                seen_y.add(second)
                point_count += 1
                root = _insert(root, point)
                continue
            if opcode == 1:
                result = int(_search(root, point))
            else:
                if root is None:
                    return INVALID_RESULT
                result = _distance_squared(point, _find_nearest(root, point, root).point)
        elif opcode in (2, 3):
            axis = first
            if axis not in (0, 1) or second != 0 or root is None:
                return INVALID_RESULT
            coordinates = [point[axis] for point in _points(root)]
            result = min(coordinates) if opcode == 2 else max(coordinates)
        else:
            return INVALID_RESULT

        checksum += (operation_index + 1) * (result + CHECKSUM_OFFSET)

    if cursor != len(values):
        return INVALID_RESULT
    return checksum
