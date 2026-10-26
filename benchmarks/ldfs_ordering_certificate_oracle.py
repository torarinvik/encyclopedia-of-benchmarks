"""Primary exact-output oracle for bounded LDFS and its 4-vertex witnesses."""

from __future__ import annotations

import struct
from collections.abc import Sequence

MAX_INPUT = 10
MAX_OUTPUT = 1872


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
    if len(values) < 3 or len(values) > MAX_INPUT or any(type(x) is not int or not -(1 << 63) <= x < (1 << 63) for x in values):
        return -1, b""
    n, start = values[:2]
    if not 1 <= n <= 8 or not 0 <= start < n or len(values) != n + 2:
        return -1, b""
    all_vertices = (1 << n) - 1
    adjacency = values[2:]
    if any(mask < 0 or mask > all_vertices or mask & (1 << vertex) for vertex, mask in enumerate(adjacency)):
        return -1, b""
    if any(bool(adjacency[a] & (1 << b)) != bool(adjacency[b] & (1 << a))
           for a in range(n) for b in range(n)):
        return -1, b""
    reached = 1 << start
    while True:
        expanded = reached
        for vertex, mask in enumerate(adjacency):
            if reached & (1 << vertex):
                expanded |= mask
        if expanded == reached:
            break
        reached = expanded
    if reached != all_vertices:
        return -1, b""

    order = [start]
    while len(order) < n:
        best = None
        for vertex in range(n):
            if vertex in order:
                continue
            label = tuple(visited for visited in reversed(order) if adjacency[vertex] & (1 << visited))
            if best is None or label > best[0] or label == best[0] and vertex < best[1]:
                best = (label, vertex)
        assert best is not None
        order.append(best[1])

    records: list[int] = []
    for i in range(n):
        for j in range(i + 1, n):
            for k in range(j + 1, n):
                a, b, c = order[i], order[j], order[k]
                if adjacency[a] & (1 << c) and not adjacency[a] & (1 << b):
                    witness = -1
                    for d in order[i + 1:j]:
                        if adjacency[d] & (1 << b) and not adjacency[d] & (1 << c):
                            witness = d
                            break
                    records.extend((a, b, c, witness))
    record_count = len(records) // 4
    fields = [n, *order, record_count, *records]
    payload = b"".join(struct.pack("<q", field) for field in fields)
    if output_is_null or capacity is not None and capacity < len(payload):
        return -2, b""
    return len(payload), payload
