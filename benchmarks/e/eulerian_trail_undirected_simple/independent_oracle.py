"""Iterative edge-discovery reference for the simple undirected profile."""

import struct


def expected_output(values, capacity=None, output_is_null=False,
                    input_is_null=False, input_length=None):
    if input_is_null or values is None:
        return -1, b""
    if input_length is not None and input_length != len(values):
        return -1, b""
    if len(values) < 2 or any(type(value) is not int for value in values):
        return -1, b""
    n, m = values[:2]
    if not 2 <= n <= 10 or not 0 <= m <= 45 or len(values) != 2 + 2 * m:
        return -1, b""
    adjacency = [[] for _ in range(n)]
    edges = set()
    for index in range(m):
        u, v = values[2 + 2 * index:4 + 2 * index]
        key = (min(u, v), max(u, v))
        if not 0 <= u < n or not 0 <= v < n or u == v or key in edges:
            return -1, b""
        edges.add(key)
        adjacency[u].append(v)
        adjacency[v].append(u)
    odd = [vertex for vertex in range(n) if len(adjacency[vertex]) % 2]
    if len(odd) not in (0, 2):
        return -1, b""
    start = odd[-1] if odd else 1
    if m and not adjacency[start]:
        return -1, b""
    reachable = {start}
    pending = [start]
    while pending:
        vertex = pending.pop()
        for neighbor in adjacency[vertex]:
            if neighbor not in reachable:
                reachable.add(neighbor)
                pending.append(neighbor)
    if any(adjacency[v] and v not in reachable for v in range(n)):
        return -1, b""
    # An explicit stack holds the next adjacency index of each active frame;
    # vertices are recorded when entering a frame, not when leaving it.
    visited_edges = set()
    discovery = [start]
    stack = [(start, 0)]
    while stack:
        vertex, position = stack[-1]
        if position == len(adjacency[vertex]):
            stack.pop()
            continue
        neighbor = adjacency[vertex][position]
        stack[-1] = (vertex, position + 1)
        edge = (min(vertex, neighbor), max(vertex, neighbor))
        if edge not in visited_edges:
            visited_edges.add(edge)
            discovery.append(neighbor)
            stack.append((neighbor, 0))
    data = b"".join(struct.pack("<q", value) for value in
                    (2 if odd else 1, len(discovery), *discovery))
    if output_is_null or capacity is not None and capacity < len(data):
        return -2, b""
    return len(data), data
