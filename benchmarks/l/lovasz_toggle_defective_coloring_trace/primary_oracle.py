"""Bounded array-backed Lovasz-toggle defective two-coloring reference."""

from __future__ import annotations

from collections.abc import Sequence

MAX_VERTICES = 16
MAX_THRESHOLD = 8
MAX_EDGES = MAX_VERTICES * (MAX_VERTICES - 1) // 2
MAX_TOGGLE_BOUND = MAX_THRESHOLD * MAX_EDGES
MAX_VALID_INPUT_LENGTH = 5 + 2 * MAX_EDGES
MAX_PARSEABLE_INPUT_LENGTH = MAX_VALID_INPUT_LENGTH + 1
WORKSPACE_BYTES = 4096
MAX_RESULT = (MAX_TOGGLE_BOUND << MAX_VERTICES) | ((1 << MAX_VERTICES) - 1)
I64_MIN = -(1 << 63)
I64_MAX = (1 << 63) - 1


def _decode(values: Sequence[int] | None, input_length: int | None,
            input_is_null: bool) -> tuple[int, int, int, int, list[tuple[int, int]]] | None:
    if type(input_is_null) is not bool or input_is_null:
        return None
    if not isinstance(values, (list, tuple)) or not 5 <= len(values) <= MAX_PARSEABLE_INPUT_LENGTH:
        return None
    if any(type(value) is not int or not I64_MIN <= value <= I64_MAX for value in values):
        return None
    declared_length = len(values) if input_length is None else input_length
    if type(declared_length) is not int or declared_length != len(values):
        return None

    vertex_count, red_limit, blue_limit, red_mask, edge_count = values[:5]
    if not 0 <= vertex_count <= MAX_VERTICES:
        return None
    if not 1 <= red_limit <= MAX_THRESHOLD or not 1 <= blue_limit <= MAX_THRESHOLD:
        return None
    if not 0 <= red_mask < (1 << vertex_count):
        return None
    if not 0 <= edge_count <= vertex_count * (vertex_count - 1) // 2:
        return None
    if len(values) != 5 + 2 * edge_count:
        return None

    edges: list[tuple[int, int]] = []
    adjacent = [0] * vertex_count
    degrees = [0] * vertex_count
    for offset in range(5, len(values), 2):
        left, right = values[offset], values[offset + 1]
        if not (0 <= left < right < vertex_count):
            return None
        right_bit = 1 << right
        if adjacent[left] & right_bit:
            return None
        adjacent[left] |= right_bit
        adjacent[right] |= 1 << left
        degrees[left] += 1
        degrees[right] += 1
        edges.append((left, right))
    if any(degree > red_limit + blue_limit + 1 for degree in degrees):
        return None
    return vertex_count, red_limit, blue_limit, red_mask, edges


def expected_result(values: Sequence[int] | None, input_is_null: bool = False,
                    input_length: int | None = None) -> int:
    """Return toggle count and terminal coloring packed into one nonnegative scalar."""
    decoded = _decode(values, input_length, input_is_null)
    if decoded is None:
        return -1
    vertex_count, red_limit, blue_limit, red_mask, edges = decoded
    neighbors = [0] * vertex_count
    for left, right in edges:
        neighbors[left] |= 1 << right
        neighbors[right] |= 1 << left

    toggles = 0
    while True:
        bad_vertex = -1
        for vertex in range(vertex_count):
            red_neighbors = (neighbors[vertex] & red_mask).bit_count()
            if red_mask & (1 << vertex):
                if red_neighbors > red_limit:
                    bad_vertex = vertex
                    break
            elif neighbors[vertex].bit_count() - red_neighbors > blue_limit:
                bad_vertex = vertex
                break
        if bad_vertex == -1:
            break
        red_mask ^= 1 << bad_vertex
        toggles += 1
    return (toggles << vertex_count) | red_mask
