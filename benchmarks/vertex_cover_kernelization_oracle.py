"""Exact output oracle for the source chapter's bounded vertex-cover reductions."""

from __future__ import annotations

import struct
from collections.abc import Sequence

MAX_INPUT = 131
MAX_OUTPUT = 1064


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
    n, m, parameter = values[:3]
    if not 1 <= n <= 16 or not 0 <= m <= 64 or not 0 <= parameter <= 16 or len(values) != 3 + 2*m:
        return -1, b""
    edges = []
    previous = (-1, -1)
    for i in range(m):
        u, v = values[3+2*i:5+2*i]
        if not 0 <= u < v < n or (u, v) <= previous:
            return -1, b""
        edges.append((u, v))
        previous = (u, v)

    adjacent = [set() for _ in range(n)]
    for u, v in edges:
        adjacent[u].add(v)
        adjacent[v].add(u)
    active = set(range(n))
    forced = set()
    remaining_parameter = parameter
    infeasible = False
    while True:
        if remaining_parameter < 0:
            infeasible = True
            break
        isolated = next((u for u in range(n) if u in active and not (adjacent[u] & active)), None)
        if isolated is not None:
            active.remove(isolated)
            continue
        leaf_choice = None
        for u in range(n):
            neighbors = sorted(adjacent[u] & active)
            if u in active and len(neighbors) == 1:
                leaf_choice = (u, neighbors[0])
                break
        if leaf_choice is not None:
            _, selected = leaf_choice
        else:
            selected = next((u for u in range(n) if u in active and len(adjacent[u] & active) > remaining_parameter), None)
            if selected is None:
                break
        forced.add(selected)
        active.remove(selected)
        remaining_parameter -= 1

    edge_list = [(u, v) for u, v in edges if u in active and v in active and v in adjacent[u]]
    payload_values = [0 if infeasible else 1, remaining_parameter,
                      sum(1 << u for u in forced), sum(1 << u for u in active), len(edge_list)]
    for u, v in edge_list:
        payload_values.extend((u, v))
    payload = b"".join(struct.pack("<q", x) for x in payload_values)
    if output_is_null or capacity is not None and capacity < len(payload):
        return -2, b""
    return len(payload), payload
