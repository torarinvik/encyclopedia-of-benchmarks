"""Complete-graph Prim reference for Manhattan minimum spanning tree weight."""

from __future__ import annotations

from collections.abc import Sequence

I64_MIN = -(1 << 63)
I64_MAX = (1 << 63) - 1


def expected_result(values: Sequence[int] | None, input_is_null: bool = False,
                    input_length: int | None = None) -> int:
    if type(input_is_null) is not bool or input_is_null:
        return -1
    if not isinstance(values, (list, tuple)) or not 1 <= len(values) <= 64:
        return -1
    if any(type(value) is not int or not I64_MIN <= value <= I64_MAX for value in values):
        return -1
    declared_length = len(values) if input_length is None else input_length
    if type(declared_length) is not int or declared_length != len(values):
        return -1
    count = values[0]
    if not 0 <= count <= 31 or len(values) != 1 + 2 * count:
        return -1

    points = []
    xs = set()
    ys = set()
    for offset in range(1, len(values), 2):
        x, y = values[offset], values[offset + 1]
        if not -1000 <= x <= 1000 or not -1000 <= y <= 1000:
            return -1
        if x in xs or y in ys:
            return -1
        xs.add(x)
        ys.add(y)
        points.append((x, y))
    if count < 2:
        return 0

    visited = [False] * count
    nearest = [10**18] * count
    nearest[0] = 0
    total = 0
    for _ in range(count):
        chosen = -1
        for vertex in range(count):
            if not visited[vertex] and (chosen < 0 or nearest[vertex] < nearest[chosen]):
                chosen = vertex
        visited[chosen] = True
        total += nearest[chosen]
        x, y = points[chosen]
        for other, (other_x, other_y) in enumerate(points):
            if not visited[other]:
                distance = abs(x - other_x) + abs(y - other_y)
                if distance < nearest[other]:
                    nearest[other] = distance
    return total
