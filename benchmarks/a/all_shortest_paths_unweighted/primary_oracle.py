"""BFS predecessor-DAG oracle for all shortest paths in a small graph."""

from __future__ import annotations

from collections.abc import Sequence

MAX_VERTICES = 16
MAX_EDGES = 64
MAX_PATHS = 162
MAX_OUTPUT_BYTES = 1296
MAX_VALID_INPUT_LENGTH = 4 + 2 * MAX_EDGES
MAX_PARSEABLE_INPUT_LENGTH = MAX_VALID_INPUT_LENGTH + 1
WORKSPACE_BYTES = 4096


def _parse(values: Sequence[int] | None, input_is_null: bool, input_length: int | None):
    if input_is_null or not isinstance(values, (tuple, list)):
        return None
    if not 4 <= len(values) <= MAX_PARSEABLE_INPUT_LENGTH:
        return None
    if input_length is not None and (type(input_length) is not int or input_length != len(values)):
        return None
    if any(type(value) is not int or not -(1 << 63) <= value < (1 << 63) for value in values):
        return None
    n, m, source, target = values[:4]
    if not 1 <= n <= MAX_VERTICES or not 0 <= m <= MAX_EDGES:
        return None
    if not 0 <= source < n or not 0 <= target < n or len(values) != 4 + 2 * m:
        return None
    adjacency = [[False] * n for _ in range(n)]
    for edge in range(m):
        u, v = values[4 + 2 * edge : 6 + 2 * edge]
        if not 0 <= u < n or not 0 <= v < n or u == v or adjacency[u][v]:
            return None
        adjacency[u][v] = adjacency[v][u] = True
    return n, source, target, adjacency


def _enumerate(n: int, source: int, target: int, adjacency: list[list[bool]]) -> tuple[int, bytes]:
    distance = [-1] * n
    predecessors = [[False] * n for _ in range(n)]
    queue = [source]
    distance[source] = 0
    for u in queue:
        for v in range(n):
            if not adjacency[u][v]:
                continue
            if distance[v] < 0:
                distance[v] = distance[u] + 1
                queue.append(v)
            if distance[v] == distance[u] + 1:
                predecessors[v][u] = True

    if distance[target] < 0:
        return 0, b""

    useful = [False] * n
    stack = [target]
    useful[target] = True
    while stack:
        v = stack.pop()
        for u in range(n):
            if predecessors[v][u] and not useful[u]:
                useful[u] = True
                stack.append(u)

    encoded = bytearray()
    path = [source]
    count = 0

    def visit(u: int) -> None:
        nonlocal count
        if u == target:
            if count == MAX_PATHS:
                raise OverflowError("shortest-path cap exceeded")
            encoded.extend(path)
            encoded.append(0xFF)
            count += 1
            return
        for v in range(n):
            if useful[v] and predecessors[v][u]:
                path.append(v)
                visit(v)
                path.pop()

    visit(source)
    if len(encoded) > MAX_OUTPUT_BYTES:
        raise OverflowError("output cap exceeded")
    return count, bytes(encoded)


def expected_output(
    values: Sequence[int] | None,
    capacity: int | None = None,
    output_is_null: bool = False,
    input_is_null: bool = False,
    input_length: int | None = None,
) -> tuple[int, bytes]:
    parsed = _parse(values, input_is_null, input_length)
    if parsed is None:
        return -1, b""
    if type(output_is_null) is not bool:
        return -1, b""
    if capacity is not None and (type(capacity) is not int or capacity < 0):
        return -1, b""
    try:
        result, output = _enumerate(*parsed)
    except OverflowError:
        return -2, b""
    if output_is_null or capacity is not None and capacity < len(output):
        return -2, b""
    return result, output
