"""Independent recursive oracle for the minimum weighted connected dominator."""

from __future__ import annotations

import struct
from collections.abc import Sequence

MAX_INPUT = 33


def expected_output(values: Sequence[int] | None, capacity: int | None = None,
                    output_is_null: bool = False, input_is_null: bool = False,
                    input_length: int | None = None) -> tuple[int, bytes]:
    if (type(output_is_null) is not bool or type(input_is_null) is not bool
            or capacity is not None and (type(capacity) is not int or capacity < 0)
            or input_length is not None and (type(input_length) is not int or not 0 <= input_length <= MAX_INPUT)
            or input_is_null and values not in (None, [], ())
            or not input_is_null and values is not None and input_length is not None and input_length != len(values)):
        return -1, b""
    if input_is_null or values is None or not isinstance(values, (list, tuple)):
        return -1, b""
    if len(values) < 3 or len(values) > MAX_INPUT or any(type(value) is not int or not -(1 << 63) <= value < (1 << 63) for value in values):
        return -1, b""
    size = values[0]
    if not 1 <= size <= 16 or len(values) != 1 + 2 * size:
        return -1, b""
    limit = (1 << size) - 1
    graph = tuple(values[1:1 + size])
    costs = tuple(values[1 + size:])
    if any(row < 0 or row > limit or row & (1 << i) for i, row in enumerate(graph)):
        return -1, b""
    if any(weight < 1 or weight > 1000 for weight in costs):
        return -1, b""
    if any(((graph[a] >> b) & 1) != ((graph[b] >> a) & 1) for a in range(size) for b in range(size)):
        return -1, b""

    optimum: tuple[int, int] | None = None

    def inspect(vertex: int, mask: int, cost: int) -> None:
        nonlocal optimum
        if vertex == size:
            if mask == 0:
                return
            dominated = mask
            for u in range(size):
                if mask & (1 << u):
                    dominated |= graph[u]
            if dominated != limit:
                return
            members = [u for u in range(size) if mask & (1 << u)]
            reached = {members[0]}
            while True:
                expanded = reached | {v for u in reached for v in range(size)
                                      if mask & (1 << v) and graph[u] & (1 << v)}
                if expanded == reached:
                    break
                reached = expanded
            if len(reached) != len(members):
                return
            candidate = (cost, mask)
            if optimum is None or candidate < optimum:
                optimum = candidate
            return
        inspect(vertex + 1, mask, cost)
        inspect(vertex + 1, mask | (1 << vertex), cost + costs[vertex])

    inspect(0, 0, 0)
    fields = [-1, 0] if optimum is None else [optimum[0], optimum[1]]
    payload = b"".join(struct.pack("<q", field) for field in fields)
    if output_is_null or capacity is not None and capacity < len(payload):
        return -2, b""
    return len(payload), payload
