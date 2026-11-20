"""Exhaustive edge-flow enumeration oracle for bounded circulations."""

from __future__ import annotations

from collections.abc import Sequence

MAX_PARSEABLE_INPUT_LENGTH = 43
COST_OFFSET = 81


def _validated_edges(values: Sequence[int] | None, input_is_null: bool,
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
    if not 1 <= n <= 8 or not 0 <= m <= 10 or len(values) != 2 + 4 * m:
        return None
    edges = []
    for i in range(m):
        u, v, capacity, cost = values[2 + 4 * i:6 + 4 * i]
        if (not 0 <= u < n or not 0 <= v < n
                or not 0 <= capacity <= 2 or not -4 <= cost <= 4):
            return None
        edges.append((u, v, capacity, cost))
    return n, edges


def expected_result(values: Sequence[int] | None,
                    input_is_null: bool = False,
                    input_length: int | None = None) -> int:
    parsed = _validated_edges(values, input_is_null, input_length)
    if parsed is None:
        return -1
    n, edges = parsed
    net = [0] * n
    minimum: int | None = None

    def enumerate_flows(edge_index: int, cost_so_far: int) -> None:
        nonlocal minimum
        if edge_index == len(edges):
            if any(net):
                return
            if minimum is None or cost_so_far < minimum:
                minimum = cost_so_far
            return
        u, v, capacity, cost = edges[edge_index]
        for flow in range(capacity + 1):
            net[u] += flow
            net[v] -= flow
            enumerate_flows(edge_index + 1, cost_so_far + flow * cost)
            net[u] -= flow
            net[v] += flow

    enumerate_flows(0, 0)
    if minimum is None:
        return -1  # Zero flow is always feasible; keep a defensive sentinel.
    return minimum + COST_OFFSET
