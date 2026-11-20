"""Lower-bound reduction and binary search for minimum nonnegative s-t flow."""

from __future__ import annotations

from collections import deque
from collections.abc import Sequence

MAX_VERTICES = 6
MAX_EDGES = 8
MAX_CAPACITY = 2
MAX_VALID_INPUT_LENGTH = 4 + 4 * MAX_EDGES
MAX_PARSEABLE_INPUT_LENGTH = MAX_VALID_INPUT_LENGTH + 1
WORKSPACE_BYTES = 1024


def _parse(values: Sequence[int] | None, input_is_null: bool,
           input_length: int | None):
    if (type(input_is_null) is not bool or input_is_null
            or not isinstance(values, (list, tuple))
            or not 4 <= len(values) <= MAX_PARSEABLE_INPUT_LENGTH
            or any(type(value) is not int or not -(1 << 63) <= value < (1 << 63)
                   for value in values)):
        return None
    if input_length is not None and (
            type(input_length) is not int or input_length != len(values)):
        return None
    n, m, source, sink = values[:4]
    if not 2 <= n <= MAX_VERTICES or not 0 <= m <= MAX_EDGES:
        return None
    if (not 0 <= source < n or not 0 <= sink < n or source == sink
            or len(values) != 4 + 4 * m):
        return None
    edges = []
    upper_bound = 0
    for i in range(m):
        u, v, lower, upper = values[4 + 4 * i:8 + 4 * i]
        if (not 0 <= u < n or not 0 <= v < n
                or not 0 <= lower <= upper <= MAX_CAPACITY):
            return None
        edges.append((u, v, lower, upper))
        if u == source and v != source:
            upper_bound += upper
    return n, source, sink, tuple(edges), upper_bound


def _feasible(n: int, source: int, sink: int, edges, flow_cap: int) -> bool:
    """Test whether the lower-bounded network admits s-t flow at most K."""
    node_cap = MAX_VERTICES + 2
    super_source = n
    super_sink = n + 1
    node_count = n + 2
    residual = [[0] * node_cap for _ in range(node_cap)]
    balance = [0] * n

    for u, v, lower, upper in edges:
        residual[u][v] += upper - lower
        balance[u] -= lower
        balance[v] += lower

    # The t->s arc closes each original s-t flow into a circulation.
    residual[sink][source] += flow_cap
    demand = 0
    for vertex, value in enumerate(balance):
        if value > 0:
            residual[super_source][vertex] += value
            demand += value
        elif value < 0:
            residual[vertex][super_sink] += -value

    flow = 0
    while flow < demand:
        parent = [-1] * node_count
        parent[super_source] = super_source
        queue = deque([super_source])
        while queue and parent[super_sink] < 0:
            u = queue.popleft()
            for v in range(node_count):
                if residual[u][v] > 0 and parent[v] < 0:
                    parent[v] = u
                    queue.append(v)
                    if v == super_sink:
                        break
        if parent[super_sink] < 0:
            break
        amount = demand - flow
        v = super_sink
        while v != super_source:
            u = parent[v]
            amount = min(amount, residual[u][v])
            v = u
        v = super_sink
        while v != super_source:
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
    n, source, sink, edges, upper_bound = parsed
    low, high = 0, upper_bound + 1  # high is the infeasible sentinel.
    while low < high:
        middle = (low + high) // 2
        if _feasible(n, source, sink, edges, middle):
            high = middle
        else:
            low = middle + 1
    return -2 if low > upper_bound else low
