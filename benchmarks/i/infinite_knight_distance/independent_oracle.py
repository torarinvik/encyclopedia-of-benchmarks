"""Bounded breadth-first reference for small infinite-board displacements."""

from __future__ import annotations

from collections import deque
from collections.abc import Sequence

MAX_COORDINATE = 1_000_000_000
MAX_BFS_OFFSET = 8
BFS_RADIUS = 24
INVALID_RESULT = -1
KNIGHT_MOVES = (
    (-2, -1), (-2, 1), (-1, -2), (-1, 2),
    (1, -2), (1, 2), (2, -1), (2, 1),
)


def _parse(values: Sequence[int] | None, input_is_null: bool,
           input_length: int | None) -> tuple[int, int] | None:
    if (type(input_is_null) is not bool or input_is_null
            or not isinstance(values, (list, tuple)) or len(values) != 2
            or any(type(value) is not int or not -(1 << 63) <= value < (1 << 63)
                   for value in values)):
        return None
    if input_length is not None and (
            type(input_length) is not int or input_length != len(values)):
        return None
    dx, dy = values
    if abs(dx) > MAX_COORDINATE or abs(dy) > MAX_COORDINATE:
        return None
    return dx, dy


def expected_result(values: Sequence[int] | None, input_is_null: bool = False,
                    input_length: int | None = None) -> int | None:
    displacement = _parse(values, input_is_null, input_length)
    if displacement is None:
        return INVALID_RESULT
    target = displacement
    if max(abs(target[0]), abs(target[1])) > MAX_BFS_OFFSET:
        return None
    if target == (0, 0):
        return 0

    queue = deque([(0, 0, 0)])
    seen = {(0, 0)}
    while queue:
        x, y, distance = queue.popleft()
        for dx, dy in KNIGHT_MOVES:
            next_x, next_y = x + dx, y + dy
            if abs(next_x) > BFS_RADIUS or abs(next_y) > BFS_RADIUS:
                continue
            next_point = (next_x, next_y)
            if next_point in seen:
                continue
            if next_point == target:
                return distance + 1
            seen.add(next_point)
            queue.append((next_x, next_y, distance + 1))
    return None
