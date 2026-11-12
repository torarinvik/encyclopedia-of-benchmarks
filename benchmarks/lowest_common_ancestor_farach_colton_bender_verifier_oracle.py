"""Independent BFS and ancestor-set verifier for batched LCA output."""

from __future__ import annotations

from collections import deque
from collections.abc import Sequence

MAX_NODES = 256
MAX_QUERIES = 1024


def _input_parts(values: Sequence[int] | None, input_is_null: bool,
                 input_length: int | None):
    if (input_is_null or not isinstance(values, (list, tuple))
            or not 4 <= len(values) <= 4 + 2 * (MAX_NODES - 1) + 2 * MAX_QUERIES
            or (input_length is not None
                and (type(input_length) is not int or input_length != len(values)))
            or any(type(value) is not int or not -(1 << 63) <= value < (1 << 63)
                   for value in values)):
        return None
    n, root, edge_count, query_count = values[:4]
    if not 1 <= n <= MAX_NODES or not 0 <= root < n or edge_count != n - 1:
        return None
    if not 0 <= query_count <= MAX_QUERIES:
        return None
    query_offset = 4 + 2 * edge_count
    if len(values) != query_offset + 2 * query_count:
        return None
    graph = [[] for _ in range(n)]
    for edge in range(edge_count):
        a = values[4 + 2 * edge]
        b = values[5 + 2 * edge]
        if not (0 <= a < n and 0 <= b < n) or a == b:
            return None
        graph[a].append(b)
        graph[b].append(a)
    pairs = []
    for q in range(query_count):
        a, b = values[query_offset + 2 * q:query_offset + 2 * q + 2]
        if not (0 <= a < n and 0 <= b < n):
            return None
        pairs.append((a, b))
    parent = [-1] * n
    depth = [0] * n
    visited = [False] * n
    queue = deque([root])
    visited[root] = True
    count = 0
    while queue:
        node = queue.popleft()
        count += 1
        for neighbor in graph[node]:
            if neighbor == parent[node]:
                continue
            if visited[neighbor]:
                return None
            visited[neighbor] = True
            parent[neighbor] = node
            depth[neighbor] = depth[node] + 1
            queue.append(neighbor)
    if count != n:
        return None
    return parent, depth, pairs


def verify_result(values: Sequence[int] | None, result: int, output: bytes,
                  output_capacity: int | None = None, output_is_null: bool = False,
                  input_is_null: bool = False, input_length: int | None = None) -> bool:
    parsed = _input_parts(values, input_is_null, input_length)
    if parsed is None:
        return result == -1 and output == b""
    parent, depth, pairs = parsed
    capacity = MAX_QUERIES if output_capacity is None else output_capacity
    if type(output_is_null) is not bool or type(capacity) is not int or capacity < 0:
        return result == -2 and output == b""
    if capacity < len(pairs) or (output_is_null and pairs):
        return result == -2 and output == b""
    if not isinstance(output, (bytes, bytearray)) or result != len(pairs) or len(output) != len(pairs):
        return False
    expected = bytearray()
    for u, v in pairs:
        ancestors: set[int] = set()
        node = u
        while node >= 0:
            ancestors.add(node)
            node = parent[node]
        node = v
        while node not in ancestors:
            node = parent[node]
        expected.append(node)
        if depth[node] > min(depth[u], depth[v]):
            return False
    return bytes(expected) == bytes(output)
