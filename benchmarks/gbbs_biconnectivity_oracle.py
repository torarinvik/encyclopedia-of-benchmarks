"""Reference implementation of a bounded GBBS Tarjan-Vishkin BCC profile."""

from __future__ import annotations

from collections.abc import Sequence

MAX_NODES = 12
MAX_EDGES = 24
MAX_INPUT_LENGTH = 2 + 2 * MAX_EDGES
INVALID_RESULT = -1
OUTPUT_ERROR = -2
I64_MIN = -(1 << 63)
I64_MAX = (1 << 63) - 1


def _parse(values: Sequence[int] | None):
    if (not isinstance(values, (list, tuple)) or len(values) < 2
            or len(values) > MAX_INPUT_LENGTH
            or any(type(value) is not int or not I64_MIN <= value <= I64_MAX
                   for value in values)):
        return None
    n, m = values[:2]
    if not 1 <= n <= MAX_NODES or not 0 <= m <= MAX_EDGES or len(values) != 2 + 2 * m:
        return None
    edges = []
    adjacent = [[False] * n for _ in range(n)]
    for pos in range(2, len(values), 2):
        u, v = values[pos:pos + 2]
        if not 0 <= u < v < n or adjacent[u][v]:
            return None
        adjacent[u][v] = adjacent[v][u] = True
        edges.append((u, v))
    return n, edges, adjacent


def _source_profile(n: int, edges: list[tuple[int, int]], adjacent: list[list[bool]]) -> bytes:
    # Deterministic multi-BFS: roots and the chosen parent within each frontier
    # are the smallest IDs. The source has this deterministic BFS variant.
    parent = list(range(n))
    seen = [False] * n
    for root in range(n):
        if seen[root]:
            continue
        seen[root] = True
        frontier = [root]
        while frontier:
            candidates: dict[int, int] = {}
            for vertex in frontier:
                for other in range(n):
                    if adjacent[vertex][other] and not seen[other]:
                        candidates[other] = min(candidates.get(other, vertex), vertex)
            following = sorted(candidates)
            for other in following:
                parent[other] = candidates[other]
                seen[other] = True
            frontier = following

    preorder_number = [0] * n
    subtree_size = [1] * n
    preorders: list[list[int]] = []
    for root in range(n):
        if parent[root] != root:
            continue
        order: list[int] = []
        stack = [root]
        while stack:
            vertex = stack.pop()
            preorder_number[vertex] = len(order)
            order.append(vertex)
            children = [child for child in range(n) if child != vertex and parent[child] == vertex]
            stack.extend(reversed(children))
        for vertex in reversed(order):
            if parent[vertex] != vertex:
                subtree_size[parent[vertex]] += subtree_size[vertex]
        preorders.append(order)

    low = preorder_number.copy()
    high = [preorder_number[v] + subtree_size[v] - 1 for v in range(n)]
    for u, v in edges:
        if parent[u] == v or parent[v] == u:
            continue
        if preorder_number[u] < low[v]:
            low[v] = preorder_number[u]
        elif preorder_number[u] > high[v]:
            high[v] = preorder_number[u]
        if preorder_number[v] < low[u]:
            low[u] = preorder_number[v]
        elif preorder_number[v] > high[u]:
            high[u] = preorder_number[v]
    for order in preorders:
        for vertex in reversed(order):
            if parent[vertex] != vertex:
                p = parent[vertex]
                low[p] = min(low[p], low[vertex])
                high[p] = max(high[p], high[vertex])

    critical = [False] * n
    for vertex in range(n):
        p = parent[vertex]
        if vertex != p and low[vertex] >= preorder_number[p] and                 high[vertex] < preorder_number[p] + subtree_size[p]:
            critical[vertex] = True

    def is_critical_edge(u: int, v: int) -> bool:
        if parent[u] == v:
            return critical[u]
        if parent[v] == u:
            return critical[v]
        return False

    component = [-1] * n
    for root in range(n):
        if component[root] != -1:
            continue
        component[root] = root
        queue = [root]
        for vertex in queue:
            for other in range(n):
                if (adjacent[vertex][other] and not is_critical_edge(vertex, other)
                        and component[other] == -1):
                    component[other] = root
                    queue.append(other)

    raw = []
    for u, v in edges:
        if parent[u] == v and critical[u]:
            raw.append(component[u])
        elif parent[v] == u and critical[v]:
            raw.append(component[v])
        else:
            raw.append(component[u])
    labels = [min(other for other, candidate in enumerate(raw) if candidate == label)
              for label in raw]
    return bytes(labels)


def expected_output(values: Sequence[int] | None, capacity: int | None = None,
                    output_is_null: bool = False, input_is_null: bool = False,
                    input_length: int | None = None) -> tuple[int, bytes]:
    if (type(output_is_null) is not bool or type(input_is_null) is not bool
            or capacity is not None and (type(capacity) is not int or capacity < 0)
            or input_length is not None and (type(input_length) is not int
                                             or not 0 <= input_length <= MAX_INPUT_LENGTH)
            or input_is_null and values not in (None, [], ())
            or not input_is_null and values is not None and input_length is not None
            and input_length != len(values)):
        return INVALID_RESULT, b""
    if input_is_null or values is None:
        return INVALID_RESULT, b""
    parsed = _parse(values)
    if parsed is None:
        return INVALID_RESULT, b""
    n, edges, adjacent = parsed
    if output_is_null or capacity is not None and capacity < len(edges):
        return OUTPUT_ERROR, b""
    return len(edges), _source_profile(n, edges, adjacent)
