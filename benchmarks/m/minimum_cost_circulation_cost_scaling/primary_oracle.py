"""Goldberg-Tarjan epsilon cost scaling for bounded integral circulations."""

from __future__ import annotations

from collections import deque
from collections.abc import Sequence

MAX_VERTICES = 8
MAX_EDGES = 10
MAX_VALID_INPUT_LENGTH = 2 + 4 * MAX_EDGES
MAX_PARSEABLE_INPUT_LENGTH = MAX_VALID_INPUT_LENGTH + 1
MAX_CAPACITY = 2
MAX_ABS_COST = 4
COST_OFFSET = 81
MAX_RESULT = 161
WORKSPACE_BYTES = 32_768


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
        u, v, capacity, cost = values[2 + 4 * i:6 + 4 * i]
        if (not 0 <= u < n or not 0 <= v < n
                or not 0 <= capacity <= MAX_CAPACITY
                or not -MAX_ABS_COST <= cost <= MAX_ABS_COST):
            return None
        edges.append((u, v, capacity, cost))
    return n, tuple(edges)


def _minimum_cost_circulation(n: int, edges) -> int:
    # Residual records are [to, reverse_index, residual_capacity, scaled_cost].
    graph: list[list[list[int]]] = [[] for _ in range(n)]
    original_arcs: list[tuple[int, int, int, int]] = []
    scale = n + 1
    for u, v, capacity, cost in edges:
        forward_index = len(graph[u])
        reverse_index = len(graph[v]) + (1 if u == v else 0)
        graph[u].append([v, reverse_index, capacity, cost * scale])
        graph[v].append([u, forward_index, 0, -cost * scale])
        original_arcs.append((u, forward_index, capacity, cost))

    max_scaled_cost = max((abs(cost * scale) for _, _, _, cost in edges), default=0)
    epsilon = 1
    while epsilon < max_scaled_cost:
        epsilon *= 2
    price = [0] * n

    while epsilon > 1:
        epsilon //= 2
        excess = [0] * n  # inflow minus outflow

        # Saturate negative reduced-cost residual arcs to make a pseudoflow.
        for u in range(n):
            for edge_index, edge in enumerate(graph[u]):
                v, reverse_index, residual_capacity, scaled_cost = edge
                if (residual_capacity > 0
                        and scaled_cost + price[u] - price[v] < 0):
                    amount = residual_capacity
                    edge[2] = 0
                    graph[v][reverse_index][2] += amount
                    excess[u] -= amount
                    excess[v] += amount

        active = deque(v for v in range(n) if excess[v] > 0)
        queued = [excess[v] > 0 for v in range(n)]
        while active:
            u = active.popleft()
            queued[u] = False
            while excess[u] > 0:
                admissible = -1
                for edge_index, edge in enumerate(graph[u]):
                    v, _, residual_capacity, scaled_cost = edge
                    if (residual_capacity > 0
                            and scaled_cost + price[u] - price[v] < 0):
                        admissible = edge_index
                        break

                if admissible >= 0:
                    edge = graph[u][admissible]
                    v, reverse_index, residual_capacity, _ = edge
                    amount = min(excess[u], residual_capacity)
                    edge[2] -= amount
                    graph[v][reverse_index][2] += amount
                    if v != u:
                        was_excess = excess[v]
                        excess[u] -= amount
                        excess[v] += amount
                        if was_excess <= 0 < excess[v] and not queued[v]:
                            active.append(v)
                            queued[v] = True
                else:
                    best_price: int | None = None
                    for edge in graph[u]:
                        v, _, residual_capacity, scaled_cost = edge
                        if residual_capacity <= 0:
                            continue
                        candidate = price[v] - scaled_cost - epsilon
                        if best_price is None or candidate > best_price:
                            best_price = candidate
                    if best_price is None:
                        raise ValueError("active circulation vertex has no residual exit")
                    price[u] = best_price

        if any(excess):
            raise ValueError("cost-scaling refinement ended with nonzero excess")

    total_cost = 0
    for u, forward_index, capacity, cost in original_arcs:
        flow = capacity - graph[u][forward_index][2]
        total_cost += flow * cost
    return total_cost


def expected_result(values: Sequence[int] | None,
                    input_is_null: bool = False,
                    input_length: int | None = None) -> int:
    parsed = _parse(values, input_is_null, input_length)
    if parsed is None:
        return -1
    n, edges = parsed
    result = _minimum_cost_circulation(n, edges) + COST_OFFSET
    return result if 1 <= result <= MAX_RESULT else -1
