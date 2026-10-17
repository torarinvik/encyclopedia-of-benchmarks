"""Independent oracle for bounded, max-first Prüfer encoding and decoding."""

from __future__ import annotations

from collections.abc import Sequence

MAX_VERTICES = 64
MAX_VALID_INPUT_LENGTH = 128
MAX_PARSEABLE_INPUT_LENGTH = 129
MAX_INPUT_LENGTH = MAX_PARSEABLE_INPUT_LENGTH
MAX_OUTPUT_BYTES = 1016
INVALID_RESULT = -1
CAPACITY_ERROR = -2
I64_MIN = -(1 << 63)
I64_MAX = (1 << 63) - 1


def _i64_le(value: int) -> bytes:
    return value.to_bytes(8, "little", signed=True)


def _encode(vertex_count: int, edges: Sequence[tuple[int, int]]) -> list[int] | None:
    if len(edges) != vertex_count - 1:
        return None
    adjacency = [set() for _ in range(vertex_count)]
    normalized: set[tuple[int, int]] = set()
    for first, second in edges:
        if not (0 <= first < vertex_count and 0 <= second < vertex_count) or first == second:
            return None
        edge = (min(first, second), max(first, second))
        if edge in normalized:
            return None
        normalized.add(edge)
        adjacency[first].add(second)
        adjacency[second].add(first)

    visited = {0}
    pending = [0]
    while pending:
        vertex = pending.pop()
        for neighbor in adjacency[vertex]:
            if neighbor not in visited:
                visited.add(neighbor)
                pending.append(neighbor)
    if len(visited) != vertex_count:
        return None

    active = set(range(vertex_count))
    degree = [len(neighbors) for neighbors in adjacency]
    code: list[int] = []
    for _ in range(max(0, vertex_count - 2)):
        leaf = max(vertex for vertex in active if degree[vertex] == 1)
        active.remove(leaf)
        neighbor = next(vertex for vertex in adjacency[leaf] if vertex in active)
        code.append(neighbor)
        degree[neighbor] -= 1
    return code


def _decode(vertex_count: int, code: Sequence[int]) -> list[tuple[int, int]]:
    remaining = [0] * vertex_count
    for vertex in code:
        remaining[vertex] += 1
    active = set(range(vertex_count))
    edges: list[tuple[int, int]] = []
    for vertex in code:
        leaf = max(candidate for candidate in active if remaining[candidate] == 0)
        active.remove(leaf)
        edges.append((min(leaf, vertex), max(leaf, vertex)))
        remaining[vertex] -= 1
    final_largest = max(active)
    active.remove(final_largest)
    final_other = max(active)
    edges.append((min(final_largest, final_other), max(final_largest, final_other)))
    return sorted(edges)


def expected_output(
    values: Sequence[int], capacity: int | None = None, output_is_null: bool = False
) -> tuple[int, bytes]:
    if (
        not isinstance(values, (list, tuple))
        or not 2 <= len(values) <= MAX_PARSEABLE_INPUT_LENGTH
        or any(type(value) is not int or not I64_MIN <= value <= I64_MAX for value in values)
    ):
        return INVALID_RESULT, b""

    mode, vertex_count = values[:2]
    if not 1 <= vertex_count <= MAX_VERTICES:
        return INVALID_RESULT, b""

    if mode == 0:
        if len(values) != 2 * vertex_count:
            return INVALID_RESULT, b""
        edge_values = values[2:]
        edges = list(zip(edge_values[::2], edge_values[1::2]))
        code = _encode(vertex_count, edges)
        if code is None:
            return INVALID_RESULT, b""
        output = b"".join(_i64_le(vertex) for vertex in code)
    elif mode == 1:
        if vertex_count < 2 or len(values) != vertex_count:
            return INVALID_RESULT, b""
        code = values[2:]
        if any(not 0 <= vertex < vertex_count for vertex in code):
            return INVALID_RESULT, b""
        edges = _decode(vertex_count, code)
        output = _i64_le(len(edges)) + b"".join(
            _i64_le(vertex) for edge in edges for vertex in edge
        )
    else:
        return INVALID_RESULT, b""

    if len(output) == 0:
        return 0, b""
    if output_is_null or (
        capacity is not None and (type(capacity) is not int or capacity < len(output))
    ):
        return CAPACITY_ERROR, b""
    return len(output), output


def expected_result(
    values: Sequence[int], capacity: int | None = None, output_is_null: bool = False
) -> tuple[int, bytes]:
    return expected_output(values, capacity, output_is_null)
