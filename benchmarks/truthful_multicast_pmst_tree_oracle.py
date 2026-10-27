"""Primary Kruskal oracle for the bounded PMST routing-tree profile."""

from __future__ import annotations

from collections.abc import Sequence

MAX_N = 8
MAX_M = 28
MAX_INPUT = 95
MAX_OUTPUT = 176


def _parse(values, input_is_null, input_length):
    if (input_is_null or not isinstance(values, (list, tuple)) or len(values) < 4
            or len(values) > MAX_INPUT
            or input_length is not None and (type(input_length) is not int or input_length != len(values))
            or any(type(x) is not int or not -(1 << 63) <= x < (1 << 63) for x in values)):
        return None
    n, m, sender, receiver_count = values[:4]
    if not 2 <= n <= MAX_N or not n - 1 <= m <= MAX_M or not 0 <= sender < n:
        return None
    if not 1 <= receiver_count < n or len(values) != 4 + 3 * m + receiver_count:
        return None
    edges = []
    previous = None
    for i in range(m):
        u, v, weight = values[4 + 3*i:7 + 3*i]
        if not (0 <= u < v < n and 1 <= weight <= 100):
            return None
        if previous is not None and (u, v) <= previous:
            return None
        previous = (u, v)
        edges.append((u, v, weight))
    receivers = tuple(values[4 + 3*m:])
    if (any(not 0 <= x < n or x == sender for x in receivers)
            or any(receivers[i] >= receivers[i + 1] for i in range(len(receivers) - 1))):
        return None
    return n, m, sender, edges, receivers


def _solve(parsed):
    n, _, sender, edges, receivers = parsed
    parent = list(range(n))

    def find(x):
        while parent[x] != x:
            parent[x] = parent[parent[x]]
            x = parent[x]
        return x

    tree = []
    for u, v, weight in sorted(edges, key=lambda edge: (edge[2], edge[0], edge[1])):
        a, b = find(u), find(v)
        if a != b:
            parent[a] = b
            tree.append((u, v, weight))
    if len(tree) != n - 1:
        return None
    adjacency = [[] for _ in range(n)]
    for edge_id, (u, v, _) in enumerate(tree):
        adjacency[u].append((v, edge_id))
        adjacency[v].append((u, edge_id))
    parent_vertex = [-1] * n
    parent_edge = [-1] * n
    parent_vertex[sender] = sender
    stack = [sender]
    while stack:
        u = stack.pop()
        for v, edge_id in adjacency[u]:
            if parent_vertex[v] == -1:
                parent_vertex[v] = u
                parent_edge[v] = edge_id
                stack.append(v)
    if any(x == -1 for x in parent_vertex):
        return None
    kept = set()
    for receiver in receivers:
        v = receiver
        while v != sender:
            kept.add(parent_edge[v])
            v = parent_vertex[v]
    output_edges = sorted((tree[i] for i in kept), key=lambda edge: (edge[0], edge[1]))
    return [len(output_edges), *(x for edge in output_edges for x in edge)]


def expected_output(values: Sequence[int] | None, output_capacity: int | None = None,
                    output_is_null: bool = False, input_is_null: bool = False,
                    input_length: int | None = None) -> tuple[int, bytes]:
    if type(output_is_null) is not bool or type(input_is_null) is not bool:
        return -1, b""
    parsed = _parse(values, input_is_null, input_length)
    if parsed is None:
        return -1, b""
    result = _solve(parsed)
    if result is None:
        return -1, b""
    payload = b"".join(x.to_bytes(8, "little", signed=True) for x in result)
    if output_capacity is not None and (type(output_capacity) is not int or output_capacity < 0):
        return -1, b""
    if output_is_null or output_capacity is not None and output_capacity < len(payload):
        return -2, b""
    return len(payload), payload
