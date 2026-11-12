"""Deterministic bounded oracle for bipartite multigraph edge coloring."""

from __future__ import annotations

from collections.abc import Sequence
import struct

MAX_SIDE_VERTICES = 5
MAX_EDGES = 10
MAX_INPUT_LENGTH = 3 + 2 * MAX_EDGES
MAX_OUTPUT_BYTES = 8 * (MAX_EDGES + 1)


def _augment(left: int, side: int, multiplicity: list[list[int]], seen: list[bool],
             right_match: list[int]) -> bool:
    for right in range(side):
        if multiplicity[left][right] == 0 or seen[right]:
            continue
        seen[right] = True
        if right_match[right] < 0 or _augment(right_match[right], side, multiplicity, seen, right_match):
            right_match[right] = left
            return True
    return False


def expected_output(
        values: Sequence[int] | None,
        capacity: int | None = None,
        output_is_null: bool = False,
        input_is_null: bool = False,
        input_length: int | None = None,
) -> tuple[int, bytes]:
    """Regularize, decompose with deterministic augmenting paths, and serialize."""
    if (
        type(output_is_null) is not bool
        or type(input_is_null) is not bool
        or (capacity is not None and (type(capacity) is not int or capacity < 0))
        or (input_length is not None
            and (type(input_length) is not int or not 0 <= input_length <= MAX_INPUT_LENGTH))
        or (input_is_null and values not in (None, [], ()))
    ):
        return -1, b""
    if input_is_null or values is None or not isinstance(values, (list, tuple)):
        return -1, b""
    if (
        len(values) < 3
        or len(values) > MAX_INPUT_LENGTH
        or any(type(value) is not int or not -(1 << 63) <= value < (1 << 63) for value in values)
        or (input_length is not None and input_length != len(values))
    ):
        return -1, b""

    left_count, right_count, edge_count = values[:3]
    if not (1 <= left_count <= MAX_SIDE_VERTICES and 1 <= right_count <= MAX_SIDE_VERTICES
            and 1 <= edge_count <= MAX_EDGES):
        return -1, b""
    if len(values) != 3 + 2 * edge_count:
        return -1, b""
    edges: list[tuple[int, int]] = []
    multiplicity = [[0] * MAX_SIDE_VERTICES for _ in range(MAX_SIDE_VERTICES)]
    left_degree = [0] * MAX_SIDE_VERTICES
    right_degree = [0] * MAX_SIDE_VERTICES
    for edge_index in range(edge_count):
        left, right = values[3 + 2 * edge_index:5 + 2 * edge_index]
        if not (0 <= left < left_count and 0 <= right < right_count):
            return -1, b""
        edges.append((left, right))
        multiplicity[left][right] += 1
        left_degree[left] += 1
        right_degree[right] += 1

    side = max(left_count, right_count)
    degree = max(max(left_degree[:side]), max(right_degree[:side]))
    original_remaining = [row[:] for row in multiplicity]
    left_deficit = [degree - left_degree[u] for u in range(side)]
    right_deficit = [degree - right_degree[v] for v in range(side)]
    while any(left_deficit):
        left = next(u for u in range(side) if left_deficit[u] > 0)
        right = next(v for v in range(side) if right_deficit[v] > 0)
        multiplicity[left][right] += 1
        left_deficit[left] -= 1
        right_deficit[right] -= 1

    colors = [-1] * edge_count
    for color in range(degree):
        right_match = [-1] * side
        for left in range(side):
            if not _augment(left, side, multiplicity, [False] * side, right_match):
                return -1, b""
        for right, left in enumerate(right_match):
            if left < 0:
                return -1, b""
            if original_remaining[left][right] > 0:
                for edge_index, (edge_left, edge_right) in enumerate(edges):
                    if (colors[edge_index] < 0 and edge_left == left and edge_right == right):
                        colors[edge_index] = color
                        break
                original_remaining[left][right] -= 1
            multiplicity[left][right] -= 1

    if any(color < 0 for color in colors):
        return -1, b""
    result_values = [degree, *colors]
    payload = b"".join(struct.pack("<Q", item) for item in result_values)
    if output_is_null or (capacity is not None and capacity < len(payload)):
        return -2, b""
    return len(payload), payload
