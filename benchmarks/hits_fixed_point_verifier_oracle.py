"""Independent dense-matrix oracle for the fixed-point HITS profile."""

from __future__ import annotations

from collections.abc import Sequence

from hits_fixed_point_oracle import (
    INVALID_RESULT,
    MAX_EDGES,
    MAX_ITERATIONS,
    MAX_PARSEABLE_INPUT_LENGTH,
    MAX_VERTICES,
    SCALE,
)


def _read(values: Sequence[int] | None, input_is_null: bool,
          input_length: int | None) -> tuple[int, int, list[list[bool]]] | None:
    if input_is_null is not False or not isinstance(values, (tuple, list)):
        return None
    length = len(values) if input_length is None else input_length
    if (type(length) is not int or length < 3 or length > MAX_PARSEABLE_INPUT_LENGTH
            or length != len(values)):
        return None
    if any(type(value) is not int or not -(1 << 63) <= value < (1 << 63) for value in values):
        return None
    vertex_count, edge_count, iterations = values[:3]
    if (not 1 <= vertex_count <= MAX_VERTICES or not 0 <= edge_count <= MAX_EDGES
            or not 0 <= iterations <= MAX_ITERATIONS or length != 3 + 2 * edge_count):
        return None
    adjacency = [[False] * vertex_count for _ in range(vertex_count)]
    for offset in range(3, length, 2):
        source, target = values[offset], values[offset + 1]
        if (not 0 <= source < vertex_count or not 0 <= target < vertex_count
                or source == target or adjacency[source][target]):
            return None
        adjacency[source][target] = True
    return vertex_count, iterations, adjacency


def _normalize(raw: list[int]) -> list[int]:
    total = sum(raw)
    if total == 0:
        return [0] * len(raw)
    return [(value * SCALE) // total for value in raw]


def expected_result(values: Sequence[int] | None, input_is_null: bool = False,
                    input_length: int | None = None) -> int:
    parsed = _read(values, input_is_null, input_length)
    if parsed is None:
        return INVALID_RESULT
    vertex_count, iterations, adjacency = parsed
    hubs = [SCALE] * vertex_count
    authorities = [0] * vertex_count
    for _ in range(iterations):
        raw_authorities = [
            sum(hubs[source] for source in range(vertex_count) if adjacency[source][target])
            for target in range(vertex_count)
        ]
        authorities = _normalize(raw_authorities)
        raw_hubs = [
            sum(authorities[target] for target in range(vertex_count) if adjacency[source][target])
            for source in range(vertex_count)
        ]
        hubs = _normalize(raw_hubs)
    return sum(
        (index + 1) * (authorities[index] + 65537 * hubs[index])
        for index in range(vertex_count)
    )
