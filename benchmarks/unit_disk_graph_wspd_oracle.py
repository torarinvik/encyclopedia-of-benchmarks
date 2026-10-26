"""Reference oracle for a bounded WSPD in an integer unit-disk graph."""

from __future__ import annotations

import struct
from collections.abc import Sequence

MAX_INPUT = 18
MAX_OUTPUT = 456


def _pack(values: list[int]) -> bytes:
    return b"".join(struct.pack("<q", value) for value in values)


def expected_output(values: Sequence[int] | None, output_capacity: int | None = None,
                    output_is_null: bool = False, input_is_null: bool = False,
                    input_length: int | None = None) -> tuple[int, bytes]:
    if (type(output_is_null) is not bool or type(input_is_null) is not bool
            or input_is_null or not isinstance(values, (list, tuple))
            or len(values) > MAX_INPUT
            or (input_length is not None and (type(input_length) is not int or input_length != len(values)))
            or any(type(value) is not int or not -(1 << 63) <= value < (1 << 63) for value in values)
            or len(values) < 4):
        return -1, b""
    n, factor = values[:2]
    if not 1 <= n <= 8 or not 1 <= factor <= 8 or len(values) != 2 + 2 * n:
        return -1, b""
    points = [tuple(values[2 + 2 * i:4 + 2 * i]) for i in range(n)]
    if any(not (-8 <= x <= 8 and -8 <= y <= 8) for x, y in points) or len(set(points)) != n:
        return -1, b""

    # On the integer lattice, distinct unit-disk edges have Euclidean length 1.
    distance = [[0 if i == j else 10**9 for j in range(n)] for i in range(n)]
    for i in range(n):
        for j in range(i + 1, n):
            dx, dy = points[i][0] - points[j][0], points[i][1] - points[j][1]
            if dx * dx + dy * dy <= 1:
                distance[i][j] = distance[j][i] = 1
    for k in range(n):
        for i in range(n):
            for j in range(n):
                distance[i][j] = min(distance[i][j], distance[i][k] + distance[k][j])
    if any(distance[i][j] >= 10**8 for i in range(n) for j in range(n)):
        return -1, b""

    def split(members: tuple[int, ...]) -> tuple[tuple[int, ...], tuple[int, ...]]:
        middle = len(members) // 2
        return members[:middle], members[middle:]

    def diameter(members: tuple[int, ...]) -> int:
        return max((distance[a][b] for a in members for b in members), default=0)

    def set_distance(a: tuple[int, ...], b: tuple[int, ...]) -> int:
        return min(distance[x][y] for x in a for y in b)

    pairs: list[tuple[int, int]] = []

    def cross(a: tuple[int, ...], b: tuple[int, ...]) -> None:
        if set_distance(a, b) >= factor * max(diameter(a), diameter(b)):
            pairs.append((sum(1 << x for x in a), sum(1 << x for x in b)))
        elif len(a) >= len(b) and len(a) > 1:
            left, right = split(a)
            cross(left, b)
            cross(right, b)
        else:
            left, right = split(b)
            cross(a, left)
            cross(a, right)

    def visit(members: tuple[int, ...]) -> None:
        if len(members) < 2:
            return
        left, right = split(members)
        visit(left)
        visit(right)
        cross(left, right)

    visit(tuple(range(n)))
    fields = [len(pairs)]
    for left, right in pairs:
        fields.extend((left, right))
    payload = _pack(fields)
    if output_capacity is not None and (type(output_capacity) is not int or output_capacity < 0):
        return -1, b""
    if output_is_null or (output_capacity is not None and output_capacity < len(payload)):
        return -2, b""
    return len(payload), payload
