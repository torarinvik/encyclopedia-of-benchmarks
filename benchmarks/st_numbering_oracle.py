"""Deterministic Even-Tarjan reference for the bounded st-numbering workload."""

from __future__ import annotations

from collections.abc import Sequence

MAX_VERTICES = 8
MAX_EDGES = 28
MAX_INPUT_LENGTH = 4 + 2 * MAX_EDGES
MAX_OUTPUT_BYTES = MAX_VERTICES
INVALID_RESULT = -1
OUTPUT_ERROR = -2


def _numbering(values: Sequence[int]) -> bytes | None:
    if (not 2 <= len(values) <= MAX_INPUT_LENGTH
            or any(type(value) is not int or not -(1 << 63) <= value < (1 << 63)
                   for value in values)):
        return None
    n, m, start, end = values[:4]
    if (not 2 <= n <= MAX_VERTICES or not 0 <= m <= MAX_EDGES
            or not 0 <= start < n or not 0 <= end < n or start == end
            or len(values) != 4 + 2 * m):
        return None

    edges: list[tuple[int, int]] = []
    masks = [0] * n
    terminal_edge: int | None = None
    for edge_index in range(m):
        u, v = values[4 + 2 * edge_index:6 + 2 * edge_index]
        if not 0 <= u < n or not 0 <= v < n or u == v:
            return None
        if masks[u] & (1 << v):
            return None
        masks[u] |= 1 << v
        masks[v] |= 1 << u
        edges.append((u, v))
        if (u == start and v == end) or (u == end and v == start):
            terminal_edge = edge_index
    if terminal_edge is None:
        return None

    # Prepending all other edges, then the selected edge, makes t the first
    # neighbor visited from s while retaining a deterministic DFS order.
    adjacency: list[list[int]] = [[] for _ in range(n)]
    for edge_index, (u, v) in enumerate(edges):
        if edge_index == terminal_edge:
            continue
        adjacency[u].insert(0, v)
        adjacency[v].insert(0, u)
    adjacency[start].insert(0, end)
    adjacency[end].insert(0, start)

    parent = [-1] * n
    discovery = [0] * n
    low_vertex = list(range(n))
    children = [0] * n
    preorder: list[int] = []
    next_neighbor = [0] * n
    stack = [start]
    clock = 1
    discovery[start] = clock
    preorder.append(start)
    while stack:
        vertex = stack[-1]
        if next_neighbor[vertex] < len(adjacency[vertex]):
            neighbor = adjacency[vertex][next_neighbor[vertex]]
            next_neighbor[vertex] += 1
            if neighbor == parent[vertex]:
                continue
            if discovery[neighbor] == 0:
                parent[neighbor] = vertex
                children[vertex] += 1
                clock += 1
                discovery[neighbor] = clock
                low_vertex[neighbor] = neighbor
                preorder.append(neighbor)
                stack.append(neighbor)
            elif discovery[neighbor] < discovery[vertex] and (
                    discovery[neighbor] < discovery[low_vertex[vertex]]):
                low_vertex[vertex] = neighbor
        else:
            stack.pop()
            ancestor = parent[vertex]
            if ancestor >= 0 and discovery[low_vertex[vertex]] < discovery[low_vertex[ancestor]]:
                low_vertex[ancestor] = low_vertex[vertex]

    if len(preorder) != n or children[start] != 1:
        return None
    for vertex in range(n):
        if vertex == start:
            continue
        for child in range(n):
            if parent[child] == vertex and discovery[low_vertex[child]] >= discovery[vertex]:
                return None

    previous = [-1] * n
    following = [-1] * n
    sign = [0] * n
    sign[start] = -1
    following[start] = end
    previous[end] = start
    head = start
    for vertex in preorder[2:]:
        ancestor = parent[vertex]
        if sign[low_vertex[vertex]] == -1:
            left = previous[ancestor]
            previous[vertex] = left
            following[vertex] = ancestor
            previous[ancestor] = vertex
            if left >= 0:
                following[left] = vertex
            else:
                head = vertex
            sign[ancestor] = 1
        else:
            right = following[ancestor]
            previous[vertex] = ancestor
            following[vertex] = right
            following[ancestor] = vertex
            if right >= 0:
                previous[right] = vertex
            sign[ancestor] = -1

    ranks = [0] * n
    rank = 1
    vertex = head
    while vertex >= 0:
        ranks[vertex] = rank
        rank += 1
        vertex = following[vertex]
    if rank != n + 1 or ranks[start] != 1 or ranks[end] != n:
        return None
    for vertex in range(n):
        if vertex == start or vertex == end:
            continue
        has_lower = any(ranks[neighbor] < ranks[vertex] for neighbor in adjacency[vertex])
        has_higher = any(ranks[neighbor] > ranks[vertex] for neighbor in adjacency[vertex])
        if not has_lower or not has_higher:
            return None
    return bytes(ranks)


def expected_output(values: Sequence[int] | None, output_capacity: int | None = None,
                    output_is_null: bool = False, input_is_null: bool = False,
                    input_length: int | None = None) -> tuple[int, bytes]:
    """Return the output-byte ABI result and a deterministic valid numbering."""
    if (type(output_is_null) is not bool or type(input_is_null) is not bool
            or output_capacity is not None
            and (type(output_capacity) is not int or output_capacity < 0)
            or not isinstance(values, (list, tuple))
            or any(type(value) is not int for value in values)
            or input_is_null and values):
        return INVALID_RESULT, b""
    if input_length is None:
        input_length = len(values)
    if (type(input_length) is not int or not 0 <= input_length <= MAX_INPUT_LENGTH
            or not input_is_null and input_length != len(values)):
        return INVALID_RESULT, b""
    if input_is_null:
        return INVALID_RESULT, b""
    result = _numbering(values)
    if result is None:
        return INVALID_RESULT, b""
    if output_is_null or output_capacity is not None and output_capacity < len(result):
        return OUTPUT_ERROR, b""
    return len(result), result
