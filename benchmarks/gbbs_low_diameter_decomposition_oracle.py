"""Source-stage oracle for bounded GBBS MPX low-diameter decomposition."""

from __future__ import annotations

from collections.abc import Sequence

MAX_NODES = 12
MAX_EDGES = 24
MAX_INPUT_LENGTH = 2 + 2 * MAX_EDGES
MAX_OUTPUT_BYTES = MAX_NODES
I64_MIN = -(1 << 63)
I64_MAX = (1 << 63) - 1

# floor(exp(round * 0.2)) for the bounded rounds used by the profile.
BATCH_SIZES = (1, 1, 1, 1, 2, 2, 3, 4, 4, 6, 7, 9, 11)


def _parse(values: Sequence[int] | None):
    if (not isinstance(values, (list, tuple)) or len(values) < 2
            or len(values) > MAX_INPUT_LENGTH
            or any(type(value) is not int or not I64_MIN <= value <= I64_MAX
                   for value in values)):
        return None
    n, m = values[:2]
    if not 1 <= n <= MAX_NODES or not 0 <= m <= MAX_EDGES:
        return None
    if len(values) != 2 + 2 * m:
        return None
    edges = []
    seen = set()
    for offset in range(2, len(values), 2):
        u, v = values[offset:offset + 2]
        if not 0 <= u < v < n or (u, v) in seen:
            return None
        seen.add((u, v))
        edges.append((u, v))
    return n, edges


def expected_output(values: Sequence[int] | None, capacity: int | None = None,
                    output_is_null: bool = False, input_is_null: bool = False,
                    input_length: int | None = None) -> tuple[int, bytes]:
    if (type(output_is_null) is not bool or type(input_is_null) is not bool
            or capacity is not None and (type(capacity) is not int or capacity < 0)
            or input_length is not None and (type(input_length) is not int
                                             or not 0 <= input_length <= MAX_INPUT_LENGTH)
            or input_is_null and values not in (None, [], ())
            or not input_is_null and values is not None and input_length is not None
            and input_length != len(values)):
        return -1, b""
    if input_is_null or values is None:
        return -1, b""
    parsed = _parse(values)
    if parsed is None:
        return -1, b""
    n, edges = parsed
    if output_is_null or capacity is not None and capacity < n:
        return -2, b""

    adjacent = [[False] * n for _ in range(n)]
    for u, v in edges:
        adjacent[u][v] = adjacent[v][u] = True
    labels = [-1] * n
    frontier: list[int] = []
    cursor = 0
    round_index = 0
    assigned = 0
    while assigned < n:
        batch = BATCH_SIZES[round_index]
        end = min(n, cursor + batch)
        for candidate in range(cursor, end):
            if labels[candidate] < 0:
                labels[candidate] = candidate
                frontier.append(candidate)
                assigned += 1
        cursor = end

        if assigned == n:
            break
        reached = [-1] * n
        for vertex in frontier:
            center = labels[vertex]
            for neighbor in range(n):
                if adjacent[vertex][neighbor] and labels[neighbor] < 0:
                    if reached[neighbor] < 0 or center < reached[neighbor]:
                        reached[neighbor] = center
        frontier = []
        for vertex, center in enumerate(reached):
            if center >= 0:
                labels[vertex] = center
                frontier.append(vertex)
                assigned += 1
        round_index += 1

    return n, bytes(labels)
