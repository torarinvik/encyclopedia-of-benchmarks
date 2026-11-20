"""Goldberg's bounded min-cut search for an exact densest induced subgraph."""

from __future__ import annotations

from collections.abc import Sequence
from math import gcd

MIN_VERTICES = 2
MAX_VERTICES = 8
MAX_EDGES = 28
MAX_VALID_INPUT_LENGTH = 2 + 2 * MAX_EDGES
MAX_PARSEABLE_INPUT_LENGTH = MAX_VALID_INPUT_LENGTH + 1
INVALID_RESULT = -1


def _parse(values: Sequence[int] | None, input_is_null: bool,
           input_length: int | None) -> tuple[int, list[tuple[int, int]]] | None:
    if (type(input_is_null) is not bool or input_is_null or values is None
            or not isinstance(values, (list, tuple))
            or not 2 <= len(values) <= MAX_PARSEABLE_INPUT_LENGTH
            or (input_length is not None
                and (type(input_length) is not int or input_length != len(values)))
            or any(type(value) is not int or not -(1 << 63) <= value < (1 << 63)
                   for value in values)):
        return None
    n, m = values[0], values[1]
    if not MIN_VERTICES <= n <= MAX_VERTICES or not 0 <= m <= MAX_EDGES:
        return None
    if len(values) != 2 + 2 * m:
        return None
    edges: list[tuple[int, int]] = []
    seen: set[tuple[int, int]] = set()
    for at in range(2, len(values), 2):
        u, v = values[at], values[at + 1]
        if not 0 <= u < v < n or (u, v) in seen:
            return None
        seen.add((u, v))
        edges.append((u, v))
    return n, edges


def _minimum_cut_source_side(capacity: list[list[int]], source: int,
                             sink: int) -> list[bool]:
    """Run deterministic Edmonds–Karp on a small dense residual matrix."""
    residual = [row[:] for row in capacity]
    count = len(residual)
    while True:
        parent = [-1] * count
        parent[source] = source
        queue = [source]
        head = 0
        while head < len(queue) and parent[sink] == -1:
            here = queue[head]
            head += 1
            for there in range(count):
                if parent[there] == -1 and residual[here][there] > 0:
                    parent[there] = here
                    queue.append(there)
                    if there == sink:
                        break
        if parent[sink] == -1:
            break
        amount = (1 << 62)
        vertex = sink
        while vertex != source:
            previous = parent[vertex]
            amount = min(amount, residual[previous][vertex])
            vertex = previous
        vertex = sink
        while vertex != source:
            previous = parent[vertex]
            residual[previous][vertex] -= amount
            residual[vertex][previous] += amount
            vertex = previous

    reachable = [False] * count
    reachable[source] = True
    queue = [source]
    head = 0
    while head < len(queue):
        here = queue[head]
        head += 1
        for there in range(count):
            if not reachable[there] and residual[here][there] > 0:
                reachable[there] = True
                queue.append(there)
    return reachable


def expected_result(values: Sequence[int] | None, input_is_null: bool = False,
                    input_length: int | None = None) -> int:
    """Return ``p*(N+1)+q`` for the reduced maximum density ``p/q``."""
    parsed = _parse(values, input_is_null, input_length)
    if parsed is None:
        return INVALID_RESULT
    n, edges = parsed
    m = len(edges)
    if m == 0:
        return 1  # 0/1, including an isolate-only graph.
    degree = [0] * n
    for u, v in edges:
        degree[u] += 1
        degree[v] += 1

    # The paper's network uses g=(low+high)/2, source arcs M, two unit
    # directed arcs per undirected edge, and sink arcs M+2g-degree(v).
    # A dyadic denominator scales every capacity to an integer exactly.
    low = 0
    high = m
    denominator = 1
    best_vertices = [False] * n
    while (high - low) * n * (n - 1) >= denominator:
        low2 = 2 * low
        high2 = 2 * high
        midpoint = low + high
        next_denominator = 2 * denominator
        source, sink = n, n + 1
        capacity = [[0] * (n + 2) for _ in range(n + 2)]
        source_capacity = m * next_denominator
        for vertex in range(n):
            capacity[source][vertex] = source_capacity
            capacity[vertex][sink] = (
                source_capacity + 2 * midpoint - next_denominator * degree[vertex]
            )
        for u, v in edges:
            capacity[u][v] += next_denominator
            capacity[v][u] += next_denominator
        reachable = _minimum_cut_source_side(capacity, source, sink)
        selected = [reachable[vertex] for vertex in range(n)]
        if any(selected):
            low, high = midpoint, high2
            best_vertices = selected
        else:
            low, high = low2, midpoint
        denominator = next_denominator

    selected_count = sum(best_vertices)
    if selected_count == 0:
        return 1
    induced_edges = sum(best_vertices[u] and best_vertices[v] for u, v in edges)
    divisor = gcd(induced_edges, selected_count)
    numerator = induced_edges // divisor
    reduced_denominator = selected_count // divisor
    return numerator * (n + 1) + reduced_denominator
