"""Edge-deletion BFS reference for DAG transitive-reduction cardinality."""

from __future__ import annotations

from collections import deque
from collections.abc import Sequence

from .primary_oracle import INVALID_RESULT, MAX_EDGES, MAX_PARSEABLE_INPUT_LENGTH, MAX_VERTICES


def expected_result(values: Sequence[int] | None, input_is_null: bool = False,
                    input_length: int | None = None) -> int:
    if (type(input_is_null) is not bool or input_is_null
            or not isinstance(values, (list, tuple))
            or not 2 <= len(values) <= MAX_PARSEABLE_INPUT_LENGTH
            or any(type(word) is not int or not -(1 << 63) <= word < (1 << 63)
                   for word in values)):
        return INVALID_RESULT
    if input_length is None:
        input_length = len(values)
    if type(input_length) is not int or input_length != len(values):
        return INVALID_RESULT
    n, m = values[0], values[1]
    if not 1 <= n <= MAX_VERTICES or not 0 <= m <= MAX_EDGES:
        return INVALID_RESULT
    if input_length != 2 + 2 * m:
        return INVALID_RESULT

    arcs: list[tuple[int, int]] = []
    seen: set[tuple[int, int]] = set()
    outgoing: list[list[tuple[int, int]]] = [[] for _ in range(n)]
    indegree = [0] * n
    for edge in range(m):
        tail, head = values[2 + 2 * edge:4 + 2 * edge]
        arc = (tail, head)
        if not 0 <= tail < n or not 0 <= head < n or tail == head or arc in seen:
            return INVALID_RESULT
        seen.add(arc)
        arcs.append(arc)
        outgoing[tail].append((head, edge))
        indegree[head] += 1

    queue = deque(vertex for vertex in range(n) if indegree[vertex] == 0)
    visited = 0
    while queue:
        vertex = queue.popleft()
        visited += 1
        for head, _ in outgoing[vertex]:
            indegree[head] -= 1
            if indegree[head] == 0:
                queue.append(head)
    if visited != n:
        return INVALID_RESULT

    retained = 0
    for removed_edge, (source, target) in enumerate(arcs):
        seen_vertices = [False] * n
        seen_vertices[source] = True
        queue = deque([source])
        while queue and not seen_vertices[target]:
            vertex = queue.popleft()
            for head, edge_id in outgoing[vertex]:
                if edge_id != removed_edge and not seen_vertices[head]:
                    seen_vertices[head] = True
                    queue.append(head)
        if not seen_vertices[target]:
            retained += 1
    return retained


def verify_candidate(values: Sequence[int] | None, result: int,
                     input_is_null: bool = False,
                     input_length: int | None = None) -> bool:
    return (type(result) is int
            and result == expected_result(values, input_is_null, input_length))
