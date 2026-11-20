"""Clean-room reference for Wigderson's 3-colorable Algorithm A profile."""

from __future__ import annotations

from collections import deque
from collections.abc import Sequence

MAX_VERTICES = 32
MAX_EDGES = 128
MAX_INPUT_LENGTH = 2 + 2 * MAX_EDGES + 1
MAX_OUTPUT_BYTES = 1 + MAX_VERTICES
WORKSPACE_BYTES = 2048


def _decode(values: Sequence[int] | None) -> tuple[int, list[list[int]]] | None:
    if (not isinstance(values, (list, tuple)) or not 2 <= len(values) <= MAX_INPUT_LENGTH
            or any(type(value) is not int or not -(1 << 63) <= value < (1 << 63)
                   for value in values)):
        return None
    n, m = values[0], values[1]
    if not 0 <= n <= MAX_VERTICES or not 0 <= m <= MAX_EDGES or len(values) != 2 + 2 * m:
        return None
    adjacency = [[] for _ in range(n)]
    seen: set[tuple[int, int]] = set()
    for offset in range(2, len(values), 2):
        u, v = values[offset:offset + 2]
        if not (0 <= u < v < n) or (u, v) in seen:
            return None
        seen.add((u, v))
        adjacency[u].append(v)
        adjacency[v].append(u)
    for neighbors in adjacency:
        neighbors.sort()
    return n, adjacency


def _color_graph(n: int, adjacency: list[list[int]]) -> bytes | None:
    active = [True] * n
    colors = [0] * n
    threshold = 0
    while (threshold + 1) * (threshold + 1) <= n:
        threshold += 1
    next_color = 1

    while True:
        chosen = -1
        maximum_degree = -1
        for vertex in range(n):
            if not active[vertex]:
                continue
            degree = sum(active[neighbor] for neighbor in adjacency[vertex])
            if degree > maximum_degree:
                chosen, maximum_degree = vertex, degree
        if chosen < 0 or maximum_degree < threshold:
            break

        in_neighborhood = [False] * n
        for neighbor in adjacency[chosen]:
            if active[neighbor]:
                in_neighborhood[neighbor] = True
        side = [-1] * n
        for root in range(n):
            if not in_neighborhood[root] or side[root] >= 0:
                continue
            side[root] = 0
            queue = deque([root])
            while queue:
                vertex = queue.popleft()
                for neighbor in adjacency[vertex]:
                    if not in_neighborhood[neighbor]:
                        continue
                    if side[neighbor] < 0:
                        side[neighbor] = 1 - side[vertex]
                        queue.append(neighbor)
                    elif side[neighbor] == side[vertex]:
                        return None
        for vertex in range(n):
            if in_neighborhood[vertex]:
                colors[vertex] = next_color + side[vertex]
        colors[chosen] = next_color + 2
        active[chosen] = False
        for neighbor in adjacency[chosen]:
            active[neighbor] = False
        # Algorithm A advances by two; the next neighborhood pair can reuse
        # this center's color because the center has no edge into the remainder.
        next_color += 2

    for vertex in range(n):
        if not active[vertex]:
            continue
        forbidden = {colors[neighbor] for neighbor in adjacency[vertex] if colors[neighbor]}
        candidate = next_color
        while candidate in forbidden:
            candidate += 1
        colors[vertex] = candidate

    palette_size = max(colors, default=0)
    return bytes([palette_size, *colors])


def expected_output(values: Sequence[int] | None, capacity: int | None = None,
                    output_is_null: bool = False, input_is_null: bool = False,
                    input_length: int | None = None) -> tuple[int, bytes]:
    if (type(output_is_null) is not bool or type(input_is_null) is not bool
            or capacity is not None and (type(capacity) is not int or capacity < 0)
            or input_length is not None and (type(input_length) is not int
                                             or not 0 <= input_length <= MAX_INPUT_LENGTH)
            or input_is_null and values not in (None, [], ())
            or not input_is_null and values is not None
            and not isinstance(values, (list, tuple))
            or not input_is_null and values is not None and input_length is not None
            and input_length != len(values)):
        return -1, b""
    if input_is_null or values is None:
        return -1, b""
    parsed = _decode(values)
    if parsed is None:
        return -1, b""
    n, adjacency = parsed
    output = _color_graph(n, adjacency)
    if output is None:
        return -1, b""
    output_capacity = MAX_OUTPUT_BYTES if capacity is None else capacity
    if output_is_null or output_capacity < len(output):
        return -2, b""
    return len(output), output
