"""Independent edge-forcing/edge-forbidding Kruskal oracle."""
from __future__ import annotations

from typing import Sequence

MAX_VERTICES = 12
MAX_EDGES = 24
MAX_VALID_INPUT_LENGTH = 2 + 3 * MAX_EDGES
MAX_PARSEABLE_INPUT_LENGTH = MAX_VALID_INPUT_LENGTH + 1
MAX_OUTPUT_BYTES = MAX_EDGES
INVALID_RESULT = -1
INSUFFICIENT_CAPACITY_RESULT = -2


def _read_graph(values: Sequence[int] | None, input_length: int | None,
                input_is_null: bool) -> tuple[int, list[tuple[int, int, int]]] | None:
    if input_is_null or not isinstance(values, (tuple, list)):
        return None
    count = len(values)
    if count < 2 or count > MAX_PARSEABLE_INPUT_LENGTH:
        return None
    if input_length is not None and (
        type(input_length) is not int or input_length != count
        or input_length < 0 or input_length > MAX_PARSEABLE_INPUT_LENGTH
    ):
        return None
    if any(type(value) is not int or value < -(1 << 63) or value >= (1 << 63)
           for value in values):
        return None
    n, m = values[0], values[1]
    if n < 1 or n > MAX_VERTICES or m < 0 or m > MAX_EDGES or count != 2 + 3 * m:
        return None
    parsed: list[tuple[int, int, int]] = []
    used: set[tuple[int, int]] = set()
    for edge_id in range(m):
        base = 2 + 3 * edge_id
        u, v, weight = values[base], values[base + 1], values[base + 2]
        if u < 0 or v <= u or v >= n or weight < 0 or weight > 20:
            return None
        if (u, v) in used:
            return None
        used.add((u, v))
        parsed.append((u, v, weight))
    return n, parsed


def _tree_weight(n: int, edges: list[tuple[int, int, int]],
                 forced: int = -1, forbidden: int = -1) -> int | None:
    leaders = list(range(n))

    def locate(x: int) -> int:
        while leaders[x] != x:
            leaders[x] = leaders[leaders[x]]
            x = leaders[x]
        return x

    chosen = 0
    total = 0
    if forced >= 0:
        u, v, weight = edges[forced]
        leaders[locate(v)] = locate(u)
        chosen = 1
        total = weight
    for edge_id in sorted(range(len(edges)), key=lambda i: (edges[i][2], i)):
        if edge_id == forced or edge_id == forbidden:
            continue
        u, v, weight = edges[edge_id]
        ru, rv = locate(u), locate(v)
        if ru != rv:
            leaders[rv] = ru
            chosen += 1
            total += weight
            if chosen == n - 1:
                break
    return total if chosen == n - 1 else None


def _classify_by_constraints(n: int, edges: list[tuple[int, int, int]]) -> bytes | None:
    optimum = _tree_weight(n, edges)
    if optimum is None:
        return None
    result = bytearray(len(edges))
    for edge_id in range(len(edges)):
        without = _tree_weight(n, edges, forbidden=edge_id)
        if without is None or without > optimum:
            result[edge_id] = 2
            continue
        with_edge = _tree_weight(n, edges, forced=edge_id)
        result[edge_id] = 1 if with_edge == optimum else 0
    return bytes(result)


def expected_output(
    values: Sequence[int] | None,
    output_capacity: int | None = None,
    output_is_null: bool = False,
    input_is_null: bool = False,
    input_length: int | None = None,
) -> tuple[int, bytes]:
    graph = _read_graph(values, input_length, input_is_null)
    if graph is None:
        return INVALID_RESULT, b""
    payload = _classify_by_constraints(*graph)
    if payload is None:
        return INVALID_RESULT, b""
    if output_capacity is not None and (
        type(output_capacity) is not int or output_capacity < 0
    ):
        return INVALID_RESULT, b""
    if len(payload) and (
        output_is_null
        or output_capacity is not None and output_capacity < len(payload)
    ):
        return INSUFFICIENT_CAPACITY_RESULT, b""
    return len(payload), payload
