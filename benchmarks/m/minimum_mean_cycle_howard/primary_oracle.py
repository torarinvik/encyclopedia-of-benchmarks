"""Exact-rational Howard policy iteration on a bounded strongly connected digraph."""

from __future__ import annotations

from collections.abc import Sequence
from fractions import Fraction
import struct

MAX_VERTICES = 8
MAX_EDGES = 16
MAX_VALID_INPUT_LENGTH = 2 + 3 * MAX_EDGES
MAX_PARSEABLE_INPUT_LENGTH = MAX_VALID_INPUT_LENGTH + 1
OUTPUT_BYTES = 16
WORKSPACE_BYTES = 2048


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
    n, edge_count = values[:2]
    if (not 1 <= n <= MAX_VERTICES
            or not 1 <= edge_count <= min(MAX_EDGES, n * n)
            or len(values) != 2 + 3 * edge_count):
        return None

    edges: list[tuple[int, int, int]] = []
    pairs: set[tuple[int, int]] = set()
    outgoing: list[list[int]] = [[] for _ in range(n)]
    forward: list[list[int]] = [[] for _ in range(n)]
    reverse: list[list[int]] = [[] for _ in range(n)]
    for i in range(edge_count):
        u, v, weight = values[2 + 3 * i:5 + 3 * i]
        if not 0 <= u < n or not 0 <= v < n or not -1000 <= weight <= 1000:
            return None
        if (u, v) in pairs:
            return None
        pairs.add((u, v))
        outgoing[u].append(i)
        forward[u].append(v)
        reverse[v].append(u)
        edges.append((u, v, weight))
    for adjacency in (forward, reverse):
        reached = {0}
        stack = [0]
        while stack:
            u = stack.pop()
            for v in adjacency[u]:
                if v not in reached:
                    reached.add(v)
                    stack.append(v)
        if len(reached) != n:
            return None
    return n, tuple(edges), tuple(tuple(row) for row in outgoing)


def _evaluate_policy(n: int, edges, policy: list[int]):
    value: list[Fraction | None] = [None] * n
    bias: list[Fraction | None] = [None] * n

    for start in range(n):
        if value[start] is not None:
            continue
        path: list[int] = []
        position: dict[int, int] = {}
        vertex = start
        while value[vertex] is None and vertex not in position:
            position[vertex] = len(path)
            path.append(vertex)
            vertex = edges[policy[vertex]][1]

        if value[vertex] is None:
            cycle_start = position[vertex]
            cycle_vertices = path[cycle_start:]
            cycle_weight = sum(edges[policy[p]][2] for p in cycle_vertices)
            cycle_mean = Fraction(cycle_weight, len(cycle_vertices))
            predecessor: dict[int, int] = {}
            for p in cycle_vertices:
                predecessor[edges[policy[p]][1]] = p
                value[p] = cycle_mean
            head = min(cycle_vertices)
            bias[head] = Fraction(0)
            current = head
            while True:
                previous = predecessor[current]
                if previous == head:
                    break
                edge_cost = edges[policy[previous]][2]
                bias[previous] = Fraction(edge_cost) - cycle_mean + bias[current]
                current = previous
            prefix = path[:cycle_start]
        else:
            prefix = path

        for p in reversed(prefix):
            edge_cost = edges[policy[p]][2]
            successor = edges[policy[p]][1]
            value[p] = value[successor]
            bias[p] = Fraction(edge_cost) - value[p] + bias[successor]

    return value, bias


def _minimum_mean(n: int, edges, outgoing) -> Fraction:
    policy = [row[0] for row in outgoing]
    policy_limit = 1
    for row in outgoing:
        policy_limit *= len(row)

    for _ in range(policy_limit + 1):
        value, bias = _evaluate_policy(n, edges, policy)
        improved = policy.copy()
        changed = False
        for u in range(n):
            current_score = (value[edges[policy[u]][1]],
                             Fraction(edges[policy[u]][2])
                             - value[edges[policy[u]][1]]
                             + bias[edges[policy[u]][1]])
            best_score = current_score
            best_edge = policy[u]
            for edge_id in outgoing[u]:
                _, v, weight = edges[edge_id]
                score = (value[v], Fraction(weight) - value[v] + bias[v])
                if score < best_score:
                    best_score = score
                    best_edge = edge_id
            if best_edge != policy[u]:
                improved[u] = best_edge
                changed = True
        if not changed:
            return min(value)
        policy = improved
    raise ValueError("Howard policy iteration exceeded its finite policy bound")


def expected_output(values: Sequence[int] | None, capacity: int | None = None,
                    output_is_null: bool = False, input_is_null: bool = False,
                    input_length: int | None = None) -> tuple[int, bytes]:
    parsed = _parse(values, input_is_null, input_length)
    if parsed is None:
        return -1, b""
    if type(output_is_null) is not bool:
        return -1, b""
    if capacity is not None and (type(capacity) is not int or capacity < 0):
        return -1, b""
    if output_is_null or (capacity is not None and capacity < OUTPUT_BYTES):
        return -2, b""
    numerator, denominator = _minimum_mean(*parsed).as_integer_ratio()
    return OUTPUT_BYTES, struct.pack("<qq", numerator, denominator)
