"""Floyd-Warshall distance oracle with decreasing-distance path generation."""

from __future__ import annotations

from collections.abc import Sequence

MAX_VERTICES = 16
MAX_EDGES = 64
MAX_PATHS = 162
MAX_OUTPUT_BYTES = 1296
MAX_VALID_INPUT_LENGTH = 4 + 2 * MAX_EDGES
MAX_PARSEABLE_INPUT_LENGTH = MAX_VALID_INPUT_LENGTH + 1


def _decode(values: Sequence[int] | None, input_is_null: bool, input_length: int | None):
    if input_is_null or not isinstance(values, (list, tuple)) or not 4 <= len(values) <= MAX_PARSEABLE_INPUT_LENGTH:
        return None
    if input_length is not None and (type(input_length) is not int or input_length != len(values)):
        return None
    if any(type(x) is not int or x < -(1 << 63) or x >= (1 << 63) for x in values):
        return None
    n, m, source, target = values[:4]
    if n < 1 or n > MAX_VERTICES or m < 0 or m > MAX_EDGES:
        return None
    if not 0 <= source < n or not 0 <= target < n or len(values) != 4 + 2 * m:
        return None
    adjacent = [[False] * n for _ in range(n)]
    for e in range(m):
        u, v = values[4 + 2 * e : 6 + 2 * e]
        if u < 0 or u >= n or v < 0 or v >= n or u == v or adjacent[u][v]:
            return None
        adjacent[u][v] = adjacent[v][u] = True
    return n, source, target, adjacent


def _floyd_enumerate(n: int, source: int, target: int, adjacent: list[list[bool]]) -> tuple[int, bytes]:
    infinity = n + 1
    distance = [[infinity] * n for _ in range(n)]
    for u in range(n):
        distance[u][u] = 0
        for v in range(n):
            if adjacent[u][v]:
                distance[u][v] = 1
    for k in range(n):
        for i in range(n):
            for j in range(n):
                candidate = distance[i][k] + distance[k][j]
                if candidate < distance[i][j]:
                    distance[i][j] = candidate

    if distance[source][target] == infinity:
        return 0, b""
    path = [source]
    encoded = bytearray()
    count = 0

    def visit(u: int) -> None:
        nonlocal count
        if u == target:
            if count >= MAX_PATHS:
                raise OverflowError("shortest-path cap exceeded")
            encoded.extend(path)
            encoded.append(0xFF)
            count += 1
            return
        remaining = distance[u][target]
        for v in range(n):
            if adjacent[u][v] and distance[v][target] == remaining - 1:
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
    decoded = _decode(values, input_is_null, input_length)
    if decoded is None:
        return -1, b""
    if type(output_is_null) is not bool:
        return -1, b""
    if capacity is not None and (type(capacity) is not int or capacity < 0):
        return -1, b""
    try:
        result, output = _floyd_enumerate(*decoded)
    except OverflowError:
        return -2, b""
    if output_is_null or capacity is not None and capacity < len(output):
        return -2, b""
    return result, output
