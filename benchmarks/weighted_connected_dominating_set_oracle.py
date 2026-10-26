"""Primary subset-enumeration oracle for exact bounded weighted CDS."""

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
    if len(values) < 3 or len(values) > MAX_INPUT or any(type(x) is not int or not -(1 << 63) <= x < (1 << 63) for x in values):
        return -1, b""
    n = values[0]
    if not 1 <= n <= 16 or len(values) != 1 + 2 * n:
        return -1, b""
    all_vertices = (1 << n) - 1
    adjacency = values[1:1 + n]
    weights = values[1 + n:]
    if any(mask < 0 or mask > all_vertices or mask & (1 << i) for i, mask in enumerate(adjacency)):
        return -1, b""
    if any(weight < 1 or weight > 1000 for weight in weights):
        return -1, b""
    if any(bool(adjacency[u] & (1 << v)) != bool(adjacency[v] & (1 << u))
           for u in range(n) for v in range(n)):
        return -1, b""

    best_cost: int | None = None
    best_mask = 0
    for selected in range(1, all_vertices + 1):
        dominated = selected
        cost = 0
        for vertex in range(n):
            if selected >> vertex & 1:
                dominated |= adjacency[vertex]
                cost += weights[vertex]
        if dominated != all_vertices:
            continue
        reached = selected & -selected
        while True:
            expanded = reached
            for vertex in range(n):
                if reached >> vertex & 1:
                    expanded |= adjacency[vertex] & selected
            if expanded == reached:
                break
            reached = expanded
        if reached == selected and (best_cost is None or cost < best_cost or cost == best_cost and selected < best_mask):
            best_cost = cost
            best_mask = selected
    fields = [-1 if best_cost is None else best_cost, best_mask]
    payload = b"".join(struct.pack("<q", field) for field in fields)
    if output_is_null or capacity is not None and capacity < len(payload):
        return -2, b""
    return len(payload), payload
