"""Independent Prim oracle for the bounded PMST tree profile."""

from __future__ import annotations

from collections.abc import Sequence


def expected_output(values: Sequence[int] | None, output_capacity: int | None = None,
                    output_is_null: bool = False, input_is_null: bool = False,
                    input_length: int | None = None) -> tuple[int, bytes]:
    if type(output_is_null) is not bool or type(input_is_null) is not bool:
        return -1, b""
    if (input_is_null or not isinstance(values, (list, tuple)) or len(values) < 4 or len(values) > 95
            or input_length is not None and (type(input_length) is not int or input_length != len(values))
            or any(type(x) is not int or not -(1 << 63) <= x < (1 << 63) for x in values)):
        return -1, b""
    n, m, sender, receiver_count = values[:4]
    if not 2 <= n <= 8 or not n - 1 <= m <= 28 or not 0 <= sender < n or not 1 <= receiver_count < n:
        return -1, b""
    if len(values) != 4 + 3*m + receiver_count:
        return -1, b""
    edges = []
    previous = None
    for i in range(m):
        u, v, w = values[4+3*i:7+3*i]
        if not 0 <= u < v < n or not 1 <= w <= 100 or previous is not None and (u, v) <= previous:
            return -1, b""
        previous = (u, v)
        edges.append((u, v, w))
    receivers = tuple(values[4+3*m:])
    if any(not 0 <= x < n or x == sender for x in receivers) or any(receivers[i] >= receivers[i+1] for i in range(len(receivers)-1)):
        return -1, b""
    visited = {sender}
    tree = []
    while len(visited) < n:
        crossing = [e for e in edges if (e[0] in visited) != (e[1] in visited)]
        if not crossing:
            return -1, b""
        edge = min(crossing, key=lambda e: (e[2], e[0], e[1]))
        tree.append(edge)
        visited.add(edge[0] if edge[1] in visited else edge[1])
    adjacency = [[] for _ in range(n)]
    for edge_id, (u, v, _) in enumerate(tree):
        adjacency[u].append((v, edge_id))
        adjacency[v].append((u, edge_id))
    parent = [-1] * n
    parent_edge = [-1] * n
    parent[sender] = sender
    stack = [sender]
    while stack:
        u = stack.pop()
        for v, edge_id in adjacency[u]:
            if parent[v] == -1:
                parent[v] = u
                parent_edge[v] = edge_id
                stack.append(v)
    kept = set()
    for receiver in receivers:
        v = receiver
        while v != sender:
            if parent[v] == -1:
                return -1, b""
            kept.add(parent_edge[v])
            v = parent[v]
    result_edges = sorted((tree[i] for i in kept), key=lambda e: (e[0], e[1]))
    result = [len(result_edges), *(x for edge in result_edges for x in edge)]
    payload = b"".join(x.to_bytes(8, "little", signed=True) for x in result)
    if output_capacity is not None and (type(output_capacity) is not int or output_capacity < 0):
        return -1, b""
    if output_is_null or output_capacity is not None and output_capacity < len(payload):
        return -2, b""
    return len(payload), payload
