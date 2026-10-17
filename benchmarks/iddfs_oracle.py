"""Reference for the bounded named-adjacency IDDFS benchmark."""

from __future__ import annotations

import struct
from collections.abc import Sequence

MAX_VERTICES = 16
MAX_NEIGHBORS = 64
MAX_DEPTH = 8
MAX_VALID_INPUT_LENGTH = 4 + 2 * MAX_VERTICES + MAX_NEIGHBORS
MAX_PARSEABLE_INPUT_LENGTH = MAX_VALID_INPUT_LENGTH + 1
MAX_OUTPUT_VALUES = 3 + MAX_DEPTH + 1
MAX_OUTPUT_BYTES = 8 * MAX_OUTPUT_VALUES
I64_MIN = -(1 << 63)
I64_MAX = (1 << 63) - 1
INVALID_RESULT = -1
OUTPUT_ERROR_RESULT = -2


def expected_output(
    values: Sequence[int] | None,
    output_capacity: int | None = None,
    output_is_null: bool = False,
    input_is_null: bool = False,
    input_length: int | None = None,
) -> tuple[int, bytes]:
    """Return the source's shallowest depth-first path and its encoded record."""
    if (type(output_is_null) is not bool or type(input_is_null) is not bool
            or (output_capacity is not None
                and (type(output_capacity) is not int or output_capacity < 0))
            or (input_length is not None and type(input_length) is not int)):
        return INVALID_RESULT, b""
    if input_is_null:
        return INVALID_RESULT, b""
    if (not isinstance(values, (list, tuple))
            or len(values) < 4
            or len(values) > MAX_PARSEABLE_INPUT_LENGTH
            or (input_length is not None and input_length != len(values))
            or any(type(value) is not int or not I64_MIN <= value <= I64_MAX
                   for value in values)):
        return INVALID_RESULT, b""

    start, target, max_depth, entry_count = values[:4]
    if (not 1 <= start <= MAX_VERTICES
            or not 1 <= target <= MAX_VERTICES
            or not 0 <= max_depth <= MAX_DEPTH
            or not 0 <= entry_count <= MAX_VERTICES):
        return INVALID_RESULT, b""

    cursor = 4
    entries: list[tuple[int, list[int]]] = []
    named_vertices: set[int] = set()
    all_neighbors: list[int] = []
    for _ in range(entry_count):
        if cursor + 2 > len(values):
            return INVALID_RESULT, b""
        vertex = values[cursor]
        degree = values[cursor + 1]
        cursor += 2
        if (not 1 <= vertex <= MAX_VERTICES
                or vertex in named_vertices
                or not 0 <= degree <= MAX_NEIGHBORS
                or degree > len(values) - cursor):
            return INVALID_RESULT, b""
        neighbors = list(values[cursor:cursor + degree])
        cursor += degree
        if any(neighbor < -MAX_VERTICES or neighbor > MAX_VERTICES
               for neighbor in neighbors):
            return INVALID_RESULT, b""
        named_vertices.add(vertex)
        all_neighbors.extend(neighbors)
        entries.append((vertex, neighbors))
    if cursor != len(values) or len(all_neighbors) > MAX_NEIGHBORS:
        return INVALID_RESULT, b""

    # R's normalizer makes all vertices from 1 through the maximum named or
    # neighbor ID, initializes missing entries as empty, then drops neighbors < 1.
    maximum_vertex = max([0, *named_vertices, *all_neighbors])
    if maximum_vertex > MAX_VERTICES:
        return INVALID_RESULT, b""
    if maximum_vertex != 0 and (start > maximum_vertex or target > maximum_vertex):
        return INVALID_RESULT, b""

    adjacency: list[list[int]] = [[] for _ in range(maximum_vertex + 1)]
    for vertex, neighbors in entries:
        adjacency[vertex] = [neighbor for neighbor in neighbors if neighbor >= 1]

    found_path: tuple[int, ...] | None = None

    def depth_limited(current: int, remaining: int, path: tuple[int, ...]) -> tuple[int, ...] | None:
        new_path = path + (current,)
        if current == target:
            return new_path
        if remaining == 0:
            return None
        for neighbor in adjacency[current]:
            if neighbor not in new_path:
                result = depth_limited(neighbor, remaining - 1, new_path)
                if result is not None:
                    return result
        return None

    if maximum_vertex != 0:
        for limit in range(max_depth + 1):
            found_path = depth_limited(start, limit, ())
            if found_path is not None:
                break

    if found_path is None:
        result_values = (0, -1, 0)
    else:
        result_values = (1, len(found_path) - 1, len(found_path), *found_path)
    encoded = b"".join(struct.pack("<q", value) for value in result_values)
    if output_is_null or (output_capacity is not None and output_capacity < len(encoded)):
        return OUTPUT_ERROR_RESULT, b""
    return len(encoded), encoded
