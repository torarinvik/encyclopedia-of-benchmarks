"""Bounded reference for Khuller–Raghavachari's k=3 DFS construction."""
from __future__ import annotations

import struct
from collections.abc import Sequence

MAX_N = 8
MAX_M = 28
MAX_VALID_INPUT_LENGTH = 2 + 2 * MAX_M
MAX_PARSEABLE_INPUT_LENGTH = MAX_VALID_INPUT_LENGTH + 1
MAX_OUTPUT_BYTES = 8 * (1 + 2 * MAX_M)


def _parse(values: Sequence[int]):
    if len(values) < 2 or len(values) > MAX_PARSEABLE_INPUT_LENGTH:
        return None
    if any(type(value) is not int or not -(1 << 63) <= value < (1 << 63)
           for value in values):
        return None
    n, m = values[:2]
    if not 4 <= n <= MAX_N or not 6 <= m <= MAX_M or len(values) != 2 + 2 * m:
        return None
    edges: list[tuple[int, int]] = []
    seen: set[tuple[int, int]] = set()
    for edge_id in range(m):
        edge = (values[2 + 2 * edge_id], values[3 + 2 * edge_id])
        if not 0 <= edge[0] < edge[1] < n or edge in seen:
            return None
        seen.add(edge)
        edges.append(edge)
    return n, m, edges


def _three_edge_connected(n: int, edges: list[tuple[int, int]]) -> bool:
    full = (1 << n) - 1
    for side in range(1, full):
        if side & 1 == 0:
            continue
        crossing = sum(((side >> u) & 1) != ((side >> v) & 1) for u, v in edges)
        if crossing < 3:
            return False
    return True


def _separated_by_one_selected_edge(n: int, edges: list[tuple[int, int]],
                                    selected: list[bool], source: int, target: int) -> bool:
    for removed in range(len(edges)):
        if not selected[removed]:
            continue
        reached = [False] * n
        reached[source] = True
        queue = [source]
        for current in queue:
            for edge_id, (u, v) in enumerate(edges):
                if not selected[edge_id] or edge_id == removed:
                    continue
                other = v if u == current else u if v == current else -1
                if other >= 0 and not reached[other]:
                    reached[other] = True
                    queue.append(other)
        if not reached[target]:
            return True
    return False


def _build(n: int, edges: list[tuple[int, int]]) -> list[bool] | None:
    adjacency: list[list[int]] = [[] for _ in range(n)]
    for edge_id, (u, v) in enumerate(edges):
        adjacency[u].append(edge_id)
        adjacency[v].append(edge_id)

    selected = [False] * len(edges)
    state = [0] * n
    discovery = [-1] * n
    finish = [-1] * n
    parent = [-1] * n
    parent_edge = [-1] * n
    postorder: list[int] = []
    clock = 0

    def visit(vertex: int) -> None:
        nonlocal clock
        state[vertex] = 1
        discovery[vertex] = clock
        clock += 1
        for edge_id in adjacency[vertex]:
            u, v = edges[edge_id]
            other = v if u == vertex else u
            if state[other] != 0:
                continue
            parent[other] = vertex
            parent_edge[other] = edge_id
            selected[edge_id] = True
            visit(other)
        state[vertex] = 2
        finish[vertex] = clock
        if parent_edge[vertex] >= 0:
            postorder.append(parent_edge[vertex])

    visit(0)
    for tree_edge in postorder:
        child = edges[tree_edge][0]
        if parent_edge[child] != tree_edge:
            child = edges[tree_edge][1]
        upper = parent[child]
        if not _separated_by_one_selected_edge(n, edges, selected, upper, child):
            continue
        best_edge = -1
        best_ancestor = n
        for edge_id, (u, v) in enumerate(edges):
            if selected[edge_id]:
                continue
            u_inside = discovery[child] <= discovery[u] < finish[child]
            v_inside = discovery[child] <= discovery[v] < finish[child]
            if u_inside == v_inside:
                continue
            ancestor = v if u_inside else u
            if discovery[ancestor] < best_ancestor:
                best_ancestor = discovery[ancestor]
                best_edge = edge_id
        if best_edge < 0:
            return None
        selected[best_edge] = True

    component = list(range(n))

    def find(vertex: int) -> int:
        while component[vertex] != vertex:
            component[vertex] = component[component[vertex]]
            vertex = component[vertex]
        return vertex

    for edge_id, (u, v) in enumerate(edges):
        if selected[edge_id]:
            continue
        left, right = find(u), find(v)
        if left != right:
            component[right] = left
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
    parsed = _parse(values)
    if parsed is None:
        return -1, b""
    n, m, edges = parsed
    if not _three_edge_connected(n, edges):
        return -1, b""
    selected = _build(n, edges)
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
