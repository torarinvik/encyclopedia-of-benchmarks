"""Timestamp-batched disjoint-set reference for secret propagation."""

from __future__ import annotations

from collections.abc import Sequence

MAX_N = 16
MAX_M = 20
MAX_TIME = 20
MAX_VALID_INPUT_LENGTH = 63
MAX_PARSEABLE_INPUT_LENGTH = 64
INVALID_RESULT = -1


def _read(values: Sequence[int] | None, input_is_null: bool,
          input_length: int | None) -> tuple[int, int, list[tuple[int, int, int]]] | None:
    if (type(input_is_null) is not bool or input_is_null
            or not isinstance(values, (list, tuple))
            or len(values) < 3 or len(values) > MAX_PARSEABLE_INPUT_LENGTH
            or any(type(v) is not int or not -(1 << 63) <= v < (1 << 63)
                   for v in values)):
        return None
    if input_length is not None and (type(input_length) is not int or input_length != len(values)):
        return None
    n, first_person, m = values[:3]
    if not 2 <= n <= MAX_N or not 1 <= first_person < n or not 0 <= m <= MAX_M:
        return None
    if len(values) != 3 + 3 * m:
        return None
    meetings: list[tuple[int, int, int]] = []
    for i in range(m):
        u, v, time = values[3 + 3 * i:6 + 3 * i]
        if not 0 <= u < n or not 0 <= v < n or u == v or not 1 <= time <= MAX_TIME:
            return None
        meetings.append((u, v, time))
    return n, first_person, meetings


def expected_result(values: Sequence[int] | None, input_is_null: bool = False,
                    input_length: int | None = None) -> int:
    decoded = _read(values, input_is_null, input_length)
    if decoded is None:
        return INVALID_RESULT
    n, first_person, meetings = decoded
    parent = list(range(n))
    size = [1] * n

    def find(node: int) -> int:
        while parent[node] != node:
            parent[node] = parent[parent[node]]
            node = parent[node]
        return node

    def union(left: int, right: int) -> None:
        a, b = find(left), find(right)
        if a == b:
            return
        if size[a] < size[b]:
            a, b = b, a
        parent[b] = a
        size[a] += size[b]

    union(0, first_person)
    for time in range(1, MAX_TIME + 1):
        touched = [False] * n
        for u, v, event_time in meetings:
            if event_time == time:
                union(u, v)
                touched[u] = touched[v] = True
        known_root = find(0)
        for node, present in enumerate(touched):
            if present and find(node) != known_root:
                parent[node] = node
                size[node] = 1

    known_root = find(0)
    return sum(1 << node for node in range(n) if find(node) == known_root)
