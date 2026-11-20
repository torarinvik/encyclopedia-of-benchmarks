"""Iterative DFS and cut-based reference for the bounded k=3 profile."""
from __future__ import annotations

import struct
from collections.abc import Sequence

MAX_N = 8
MAX_M = 28
MAX_PARSEABLE_INPUT_LENGTH = 59


def _read(values: Sequence[int]):
    if len(values) < 2 or len(values) > MAX_PARSEABLE_INPUT_LENGTH:
        return None
    if any(type(value) is not int or not -(1 << 63) <= value < (1 << 63)
           for value in values):
        return None
    n, m = values[0], values[1]
    if not 4 <= n <= MAX_N or not 6 <= m <= MAX_M or len(values) != 2 + 2 * m:
        return None
    edges: list[tuple[int, int]] = []
    seen: set[tuple[int, int]] = set()
    for record in range(m):
        a, b = values[2 + 2 * record], values[3 + 2 * record]
        if not 0 <= a < b < n or (a, b) in seen:
            return None
        seen.add((a, b))
        edges.append((a, b))
    return n, m, edges


def _cut_connected(n: int, edges: list[tuple[int, int]]) -> bool:
    full = (1 << n) - 1
    for side in range(1, full):
        if not side & 1:
            continue
        cut_size = 0
        for u, v in edges:
            if ((side >> u) ^ (side >> v)) & 1:
                cut_size += 1
        if cut_size < 3:
            return False
    return True


def _has_one_edge_cut(n: int, edges: list[tuple[int, int]], selected: list[bool],
                      source: int, target: int) -> bool:
    for side in range(1, (1 << n) - 1):
        if not (side >> source) & 1 or (side >> target) & 1:
            continue
        crossing = 0
        for edge_id, (u, v) in enumerate(edges):
            if selected[edge_id] and ((side >> u) ^ (side >> v)) & 1:
                crossing += 1
        if crossing <= 1:
            return True
    return False


def _construct(n: int, edges: list[tuple[int, int]]) -> list[bool] | None:
    adjacency: list[list[int]] = [[] for _ in range(n)]
    for edge_id, (u, v) in enumerate(edges):
        adjacency[u].append(edge_id)
        adjacency[v].append(edge_id)
    selected = [False] * len(edges)
    state = [False] * n
    discovery = [-1] * n
    exit_time = [-1] * n
    parent = [-1] * n
    parent_edge = [-1] * n
    postorder: list[int] = []
    clock = 0
    state[0] = True
    discovery[0] = clock
    clock += 1
    stack = [[0, 0]]
    while stack:
        vertex, slot = stack[-1]
        if slot < len(adjacency[vertex]):
            edge_id = adjacency[vertex][slot]
            stack[-1][1] += 1
            u, v = edges[edge_id]
            other = v if u == vertex else u
            if state[other]:
                continue
            state[other] = True
            parent[other] = vertex
            parent_edge[other] = edge_id
            selected[edge_id] = True
            discovery[other] = clock
            clock += 1
            stack.append([other, 0])
        else:
            exit_time[vertex] = clock
            stack.pop()
            if parent_edge[vertex] >= 0:
                postorder.append(parent_edge[vertex])

    for tree_edge in postorder:
        a, b = edges[tree_edge]
        child = a if parent_edge[a] == tree_edge else b
        upper = parent[child]
        if not _has_one_edge_cut(n, edges, selected, upper, child):
            continue
        candidate = -1
        earliest_ancestor = n
        for edge_id, (u, v) in enumerate(edges):
            if selected[edge_id]:
                continue
            a_inside = discovery[child] <= discovery[u] < exit_time[child]
            b_inside = discovery[child] <= discovery[v] < exit_time[child]
            if a_inside == b_inside:
                continue
            ancestor = v if a_inside else u
            if discovery[ancestor] < earliest_ancestor:
                earliest_ancestor = discovery[ancestor]
                candidate = edge_id
        if candidate < 0:
            return None
        selected[candidate] = True

    leaders = list(range(n))

    def root(vertex: int) -> int:
        while leaders[vertex] != vertex:
            leaders[vertex] = leaders[leaders[vertex]]
            vertex = leaders[vertex]
        return vertex

    for edge_id, (u, v) in enumerate(edges):
        if selected[edge_id]:
            continue
        left, right = root(u), root(v)
        if left != right:
            leaders[right] = left
            selected[edge_id] = True
    return selected


def expected_output(values: Sequence[int] | None, capacity: int | None = None,
                    output_is_null: bool = False, input_is_null: bool = False,
                    input_length: int | None = None) -> tuple[int, bytes]:
    if (type(output_is_null) is not bool or type(input_is_null) is not bool
            or capacity is not None and (type(capacity) is not int or capacity < 0)
            or input_length is not None and (type(input_length) is not int or input_length < 0)
            or input_is_null and values not in (None, [], ())
            or not input_is_null and values is not None and not isinstance(values, (list, tuple))
            or not input_is_null and values is not None and input_length is not None
            and input_length != len(values)):
        return -1, b""
    if input_is_null or values is None or not isinstance(values, (list, tuple)):
        return -1, b""
    parsed = _read(values)
    if parsed is None:
        return -1, b""
    n, m, edges = parsed
    if not _cut_connected(n, edges):
        return -1, b""
    selected = _construct(n, edges)
    if selected is None:
        return -1, b""
    chosen = [(u, v) for edge_id, (u, v) in enumerate(edges) if selected[edge_id]]
    payload = struct.pack("<" + "q" * (1 + 2 * len(chosen)), len(chosen),
                          *(endpoint for edge in chosen for endpoint in edge))
    if output_is_null or capacity is not None and capacity < len(payload):
        return -2, b""
    return len(payload), payload


def expected_result(values: Sequence[int] | None) -> int:
    return expected_output(values)[0]
