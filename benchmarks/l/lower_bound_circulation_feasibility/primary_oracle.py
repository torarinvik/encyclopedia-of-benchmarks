"""Lower/upper-bound circulation via the standard super-source reduction."""

from __future__ import annotations

from collections import deque
from collections.abc import Sequence

MAX_VERTICES = 6
MAX_EDGES = 8
MAX_CAPACITY = 2
MAX_VALID_INPUT_LENGTH = 2 + 4 * MAX_EDGES
MAX_PARSEABLE_INPUT_LENGTH = MAX_VALID_INPUT_LENGTH + 1
WORKSPACE_BYTES = 1024


def _parse(values: Sequence[int] | None, input_is_null: bool,
           input_length: int | None):
    if (type(input_is_null) is not bool or input_is_null
            or not isinstance(values, (list, tuple))
            or not 2 <= len(values) <= MAX_PARSEABLE_INPUT_LENGTH
            or any(type(value) is not int or not -(1 << 63) <= value < (1 << 63)
                   for value in values)):
        return None
    if input_length is not None and (
            type(input_length) is not int or input_length != len(values)):
        return None
    n, m = values[:2]
    if not 1 <= n <= MAX_VERTICES or not 0 <= m <= MAX_EDGES:
        return None
    if len(values) != 2 + 4 * m:
        return None
    edges = []
    for i in range(m):
        u, v, lower, upper = values[2 + 4 * i:6 + 4 * i]
        if (not 0 <= u < n or not 0 <= v < n
                or not 0 <= lower <= upper <= MAX_CAPACITY):
            return None
        edges.append((u, v, lower, upper))
    return n, edges


def _reduction_feasible(n: int, edges) -> bool:
    source, sink = n, n + 1
    node_count = n + 2
    residual = [[0] * node_count for _ in range(node_count)]
    balance = [0] * n
    for u, v, lower, upper in edges:
        residual[u][v] += upper - lower
        balance[u] -= lower
        balance[v] += lower

    demand = 0
    for vertex, value in enumerate(balance):
        if value > 0:
            residual[source][vertex] += value
            demand += value
        elif value < 0:
            residual[vertex][sink] += -value

    flow = 0
    while True:
        parent = [-1] * node_count
        parent[source] = source
        queue = deque([source])
        while queue and parent[sink] < 0:
            u = queue.popleft()
            for v, capacity in enumerate(residual[u]):
                if capacity > 0 and parent[v] < 0:
                    parent[v] = u
                    queue.append(v)
                    if v == sink:
                        break
        if parent[sink] < 0:
            break
        amount = demand - flow
        v = sink
        while v != source:
            u = parent[v]
            amount = min(amount, residual[u][v])
            v = u
        v = sink
        while v != source:
            u = parent[v]
            residual[u][v] -= amount
            residual[v][u] += amount
            v = u
        flow += amount
    return flow == demand


def expected_result(values: Sequence[int] | None,
                    input_is_null: bool = False,
                    input_length: int | None = None) -> int:
    parsed = _parse(values, input_is_null, input_length)
    if parsed is None:
        return -1
    n, edges = parsed
    return int(_reduction_feasible(n, edges))
