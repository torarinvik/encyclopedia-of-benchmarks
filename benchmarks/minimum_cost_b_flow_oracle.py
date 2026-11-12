"""Bounded minimum-cost b-flow oracle and independent certificate checker."""
from __future__ import annotations

import itertools
import struct
from typing import Sequence

MAX_VERTICES = 8
MAX_EDGES = 10
MAX_BALANCE = 5
MAX_ABS_BOUND = 3
MAX_EDGE_WIDTH = 2
MAX_ABS_COST = 4
MAX_VALID_INPUT_LENGTH = 2 + MAX_VERTICES + 5 * MAX_EDGES
MAX_PARSEABLE_INPUT_LENGTH = MAX_VALID_INPUT_LENGTH + 1
MAX_OUTPUT_BYTES = 8 * (2 + MAX_VERTICES + MAX_EDGES)
INVALID_RESULT = -1
OUTPUT_ERROR = -2
POTENTIAL_LIMIT = 10**15


def _parse(values: Sequence[int] | None, input_length: int | None,
           input_is_null: bool) -> tuple[int, list[int], list[tuple[int, int, int, int, int]]] | None:
    if (type(input_is_null) is not bool or input_is_null or not isinstance(values, (list, tuple))
            or len(values) < 2 or len(values) > MAX_PARSEABLE_INPUT_LENGTH
            or (input_length is not None
                and (type(input_length) is not int or input_length != len(values)
                     or not 0 <= input_length <= MAX_PARSEABLE_INPUT_LENGTH))
            or any(type(value) is not int or not -(1 << 63) <= value < (1 << 63)
                   for value in values)):
        return None
    vertex_count, edge_count = values[:2]
    if not 0 <= vertex_count <= MAX_VERTICES or not 0 <= edge_count <= MAX_EDGES:
        return None
    expected_length = 2 + vertex_count + 5 * edge_count
    if len(values) != expected_length:
        return None
    balances = list(values[2:2 + vertex_count])
    if any(abs(balance) > MAX_BALANCE for balance in balances):
        return None
    edges: list[tuple[int, int, int, int, int]] = []
    offset = 2 + vertex_count
    for edge_id in range(edge_count):
        source, target, lower, upper, cost = values[offset + 5 * edge_id:offset + 5 * edge_id + 5]
        if (not 0 <= source < vertex_count or not 0 <= target < vertex_count
                or not -MAX_ABS_BOUND <= lower <= upper <= MAX_ABS_BOUND
                or upper - lower > MAX_EDGE_WIDTH or abs(cost) > MAX_ABS_COST):
            return None
        edges.append((source, target, lower, upper, cost))
    return vertex_count, balances, edges


def _build_residual(vertex_count: int, edges: Sequence[tuple[int, int, int, int, int]]):
    source: list[int] = []
    target: list[int] = []
    capacity: list[int] = []
    cost: list[int] = []
    reverse: list[int] = []

    def add_edge(left: int, right: int, cap: int, price: int) -> int:
        forward = len(source)
        source.extend((left, right))
        target.extend((right, left))
        capacity.extend((cap, 0))
        cost.extend((price, -price))
        reverse.extend((forward + 1, forward))
        return forward

    for left, right, lower, upper, price in edges:
        add_edge(left, right, upper - lower, price)
    return source, target, capacity, cost, reverse, add_edge


def _solve(vertex_count: int, balances: Sequence[int],
           edges: Sequence[tuple[int, int, int, int, int]]) -> list[int]:
    required = list(balances)
    for left, right, lower, _upper, _price in edges:
        required[left] -= lower
        required[right] += lower
    payload_tail = [0] * (vertex_count + len(edges))
    if sum(required) != 0:
        return [0, 0, *payload_tail]

    source, target, capacity, cost, reverse, add_edge = _build_residual(vertex_count, edges)
    super_source, super_sink = vertex_count, vertex_count + 1
    required_flow = 0
    for vertex, balance in enumerate(required):
        if balance > 0:
            add_edge(super_source, vertex, balance, 0)
            required_flow += balance
        elif balance < 0:
            add_edge(vertex, super_sink, -balance, 0)

    sent = 0
    node_count = vertex_count + 2
    while sent < required_flow:
        parent = [-1] * node_count
        seen = [False] * node_count
        queue = [super_source]
        seen[super_source] = True
        for vertex in queue:
            for edge_id in range(len(source)):
                neighbor = target[edge_id]
                if (source[edge_id] == vertex and capacity[edge_id] > 0
                        and not seen[neighbor]):
                    seen[neighbor] = True
                    parent[neighbor] = edge_id
                    queue.append(neighbor)
        if not seen[super_sink]:
            return [0, 0, *payload_tail]
        amount = required_flow - sent
        vertex = super_sink
        while vertex != super_source:
            edge_id = parent[vertex]
            amount = min(amount, capacity[edge_id])
            vertex = source[edge_id]
        vertex = super_sink
        while vertex != super_source:
            edge_id = parent[vertex]
            capacity[edge_id] -= amount
            capacity[reverse[edge_id]] += amount
            vertex = source[edge_id]
        sent += amount

    active_edges = 2 * len(edges)
    if vertex_count > 0:
        while True:
            distance = [0] * vertex_count
            parent = [-1] * vertex_count
            changed_vertex = -1
            for _ in range(vertex_count):
                changed_vertex = -1
                for edge_id in range(active_edges):
                    if (capacity[edge_id] > 0
                            and distance[target[edge_id]] > distance[source[edge_id]] + cost[edge_id]):
                        distance[target[edge_id]] = distance[source[edge_id]] + cost[edge_id]
                        parent[target[edge_id]] = edge_id
                        changed_vertex = target[edge_id]
                if changed_vertex == -1:
                    break
            if changed_vertex == -1:
                break
            on_cycle = changed_vertex
            for _ in range(vertex_count):
                edge_id = parent[on_cycle]
                if edge_id < 0:
                    return [0, 0, *payload_tail]
                on_cycle = source[edge_id]
            cycle: list[int] = []
            vertex = on_cycle
            while True:
                edge_id = parent[vertex]
                if edge_id < 0:
                    return [0, 0, *payload_tail]
                cycle.append(edge_id)
                vertex = source[edge_id]
                if vertex == on_cycle:
                    break
            amount = min(capacity[edge_id] for edge_id in cycle)
            for edge_id in cycle:
                capacity[edge_id] -= amount
                capacity[reverse[edge_id]] += amount

    potential = [0] * vertex_count
    for _ in range(max(0, vertex_count - 1)):
        changed = False
        for edge_id in range(active_edges):
            if (capacity[edge_id] > 0
                    and potential[target[edge_id]] > potential[source[edge_id]] + cost[edge_id]):
                potential[target[edge_id]] = potential[source[edge_id]] + cost[edge_id]
                changed = True
        if not changed:
            break
    flows = [upper - capacity[2 * edge_id]
             for edge_id, (_left, _right, _lower, upper, _price) in enumerate(edges)]
    total_cost = sum(edge[4] * flow for edge, flow in zip(edges, flows))
    return [1, total_cost, *potential, *flows]


def _has_feasible_flow(vertex_count: int, balances: Sequence[int],
                       edges: Sequence[tuple[int, int, int, int, int]]) -> bool:
    ranges = [range(lower, upper + 1) for _u, _v, lower, upper, _cost in edges]
    for flows in itertools.product(*ranges):
        divergence = [0] * vertex_count
        for (left, right, _lower, _upper, _price), flow in zip(edges, flows):
            divergence[left] += flow
            divergence[right] -= flow
        if divergence == list(balances):
            return True
    return False


def validate_output(values: Sequence[int] | None, payload: bytes) -> bool:
    parsed = _parse(values, None, False)
    if parsed is None or not isinstance(payload, (bytes, bytearray)):
        return False
    vertex_count, balances, edges = parsed
    word_count = 2 + vertex_count + len(edges)
    if len(payload) != 8 * word_count:
        return False
    words = struct.unpack("<" + "q" * word_count, payload)
    status, total_cost = words[:2]
    potentials = words[2:2 + vertex_count]
    flows = words[2 + vertex_count:]
    if status == 0:
        return (total_cost == 0 and all(value == 0 for value in potentials + flows)
                and not _has_feasible_flow(vertex_count, balances, edges))
    if status != 1 or any(abs(value) > POTENTIAL_LIMIT for value in potentials):
        return False
    divergence = [0] * vertex_count
    computed_cost = 0
    for (left, right, lower, upper, price), flow in zip(edges, flows):
        if not lower <= flow <= upper:
            return False
        divergence[left] += flow
        divergence[right] -= flow
        computed_cost += price * flow
        reduced = price + potentials[left] - potentials[right]
        if flow > lower and reduced > 0:
            return False
        if flow < upper and reduced < 0:
            return False
    return divergence == list(balances) and computed_cost == total_cost


def expected_output(
    values: Sequence[int] | None,
    output_capacity: int | None = None,
    output_is_null: bool = False,
    input_is_null: bool = False,
    input_length: int | None = None,
) -> tuple[int, bytes]:
    if type(output_is_null) is not bool or type(input_is_null) is not bool:
        return INVALID_RESULT, b""
    parsed = _parse(values, input_length, input_is_null)
    if parsed is None:
        return INVALID_RESULT, b""
    vertex_count, balances, edges = parsed
    result = _solve(vertex_count, balances, edges)
    payload = struct.pack("<" + "q" * len(result), *result)
    if not validate_output(values, payload):
        return INVALID_RESULT, b""
    if output_capacity is not None and (type(output_capacity) is not int or output_capacity < 0):
        return INVALID_RESULT, b""
    if output_is_null or (output_capacity is not None and output_capacity < len(payload)):
        return OUTPUT_ERROR, b""
    return len(payload), payload
