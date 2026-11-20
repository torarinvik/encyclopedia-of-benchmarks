"""Deterministic fixed-point HITS hub-authority ranking oracle."""

from __future__ import annotations

from collections.abc import Sequence

MAX_VERTICES = 16
MAX_EDGES = 64
MAX_ITERATIONS = 32
SCALE = 1_000_000
MAX_VALID_INPUT_LENGTH = 3 + 2 * MAX_EDGES
MAX_PARSEABLE_INPUT_LENGTH = MAX_VALID_INPUT_LENGTH + 1
INVALID_RESULT = -1


def _parse(values: Sequence[int] | None, input_is_null: bool,
           input_length: int | None) -> tuple[int, int, list[tuple[int, int]]] | None:
    if type(input_is_null) is not bool or input_is_null or not isinstance(values, (list, tuple)):
        return None
    actual_length = len(values) if input_length is None else input_length
    if (type(actual_length) is not int or actual_length < 3
            or actual_length > MAX_PARSEABLE_INPUT_LENGTH or actual_length != len(values)):
        return None
    if any(type(value) is not int or not -(1 << 63) <= value < (1 << 63) for value in values):
        return None
    vertex_count, edge_count, iterations = values[:3]
    if not 1 <= vertex_count <= MAX_VERTICES or not 0 <= edge_count <= MAX_EDGES:
        return None
    if not 0 <= iterations <= MAX_ITERATIONS or actual_length != 3 + 2 * edge_count:
        return None
    edges: list[tuple[int, int]] = []
    seen: set[tuple[int, int]] = set()
    for offset in range(3, actual_length, 2):
        source, target = values[offset], values[offset + 1]
        if not (0 <= source < vertex_count and 0 <= target < vertex_count) or source == target:
            return None
        edge = (source, target)
        if edge in seen:
            return None
        seen.add(edge)
        edges.append(edge)
    return vertex_count, iterations, edges


def _normalize(raw: list[int]) -> list[int]:
    total = sum(raw)
    if total == 0:
        return [0] * len(raw)
    return [(value * SCALE) // total for value in raw]


def expected_result(values: Sequence[int] | None, input_is_null: bool = False,
                    input_length: int | None = None) -> int:
    parsed = _parse(values, input_is_null, input_length)
    if parsed is None:
        return INVALID_RESULT
    vertex_count, iterations, edges = parsed
    hubs = [SCALE] * vertex_count
    authorities = [0] * vertex_count
    for _ in range(iterations):
        raw_authorities = [0] * vertex_count
        for source, target in edges:
            raw_authorities[target] += hubs[source]
        authorities = _normalize(raw_authorities)

        raw_hubs = [0] * vertex_count
        for source, target in edges:
            raw_hubs[source] += authorities[target]
        hubs = _normalize(raw_hubs)
    return sum(
        (index + 1) * (authorities[index] + 65537 * hubs[index])
        for index in range(vertex_count)
    )
