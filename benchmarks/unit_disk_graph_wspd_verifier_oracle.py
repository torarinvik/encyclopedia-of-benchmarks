"""Independent iterative verifier oracle for the unit-disk graph WSPD profile."""

from __future__ import annotations

import struct
from collections.abc import Sequence


def expected_output(values: Sequence[int] | None, output_capacity: int | None = None,
                    output_is_null: bool = False, input_is_null: bool = False,
                    input_length: int | None = None) -> tuple[int, bytes]:
    if (input_is_null or values is None or not isinstance(values, (list, tuple))
            or len(values) < 4 or len(values) > 18
            or input_length is not None and input_length != len(values)
            or any(type(x) is not int or not -(1 << 63) <= x < (1 << 63) for x in values)):
        return -1, b""
    n, c = values[0], values[1]
    if not 1 <= n <= 8 or not 1 <= c <= 8 or len(values) != 2 + 2 * n:
        return -1, b""
    xy = [(values[2 + 2*i], values[3 + 2*i]) for i in range(n)]
    if len(set(xy)) != n or any(not -8 <= q <= 8 for point in xy for q in point):
        return -1, b""
    inf = 10**9
    dist = [[0 if i == j else inf for j in range(n)] for i in range(n)]
    for i in range(n):
        for j in range(i):
            dx = xy[i][0] - xy[j][0]
            dy = xy[i][1] - xy[j][1]
            if dx*dx + dy*dy <= 1:
                dist[i][j] = dist[j][i] = 1
    for k in range(n):
        for i in range(n):
            for j in range(n):
                alt = dist[i][k] + dist[k][j]
                if alt < dist[i][j]:
                    dist[i][j] = alt
    if max(map(max, dist)) >= inf:
        return -1, b""

    def diameter(a: tuple[int, ...]) -> int:
        return max(dist[i][j] for i in a for j in a)

    def separation(a: tuple[int, ...], b: tuple[int, ...]) -> bool:
        nearest = min(dist[i][j] for i in a for j in b)
        return nearest >= c * max(diameter(a), diameter(b))

    output_pairs: list[tuple[int, int]] = []
    # Events make the traversal independent of the primary oracle's recursive walk.
    events: list[tuple[str, tuple[int, ...], tuple[int, ...]]] = [
        ("visit", tuple(range(n)), ())
    ]
    while events:
        kind, a, b = events.pop()
        if kind == "visit":
            if len(a) < 2:
                continue
            mid = len(a) // 2
            left, right = a[:mid], a[mid:]
            events.append(("cross", left, right))
            events.append(("visit", right, ()))
            events.append(("visit", left, ()))
            continue
        if separation(a, b):
            output_pairs.append((sum(1 << i for i in a), sum(1 << i for i in b)))
            continue
        if len(a) >= len(b) and len(a) > 1:
            mid = len(a) // 2
            first, second = a[:mid], a[mid:]
            events.append(("cross", second, b))
            events.append(("cross", first, b))
        else:
            mid = len(b) // 2
            first, second = b[:mid], b[mid:]
            events.append(("cross", a, second))
            events.append(("cross", a, first))
    words = [len(output_pairs)]
    for first, second in output_pairs:
        words.extend((first, second))
    payload = b"".join(struct.pack("<q", word) for word in words)
    if output_capacity is not None and (type(output_capacity) is not int or output_capacity < 0):
        return -1, b""
    if output_is_null or output_capacity is not None and output_capacity < len(payload):
        return -2, b""
    return len(payload), payload
