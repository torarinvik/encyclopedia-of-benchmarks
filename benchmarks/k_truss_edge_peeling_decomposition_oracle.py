"""Primary bounded edge-peeling oracle for simple-graph trussness."""

from __future__ import annotations

import struct
from collections.abc import Sequence

MAX_VERTICES = 16
MAX_EDGES = 120
MAX_PARSEABLE_INPUT = 243
I64_MIN = -(1 << 63)
I64_MAX = (1 << 63) - 1
INVALID_RESULT = -1
OUTPUT_ERROR = -2


def _parse(values: Sequence[int] | None):
    if (not isinstance(values, (list, tuple)) or len(values) < 2
            or len(values) > MAX_PARSEABLE_INPUT
            or any(type(value) is not int or not I64_MIN <= value <= I64_MAX
                   for value in values)):
        return None
    n, m = values[:2]
    if not 1 <= n <= MAX_VERTICES or not 0 <= m <= MAX_EDGES or len(values) != 2 + 2 * m:
        return None
    edges: list[tuple[int, int]] = []
    seen: set[tuple[int, int]] = set()
    for offset in range(2, len(values), 2):
        u, v = values[offset : offset + 2]
        if not 0 <= u < v < n or (u, v) in seen:
            return None
        seen.add((u, v))
        edges.append((u, v))
    return n, edges


def expected_output(
    values: Sequence[int] | None,
    output_capacity: int | None = None,
    output_is_null: bool = False,
    input_is_null: bool = False,
    input_length: int | None = None,
) -> tuple[int, bytes]:
    """Peel a minimum-support edge, clamping surviving supports to the level."""
    if (type(output_is_null) is not bool or type(input_is_null) is not bool
            or output_capacity is not None and
            (type(output_capacity) is not int or output_capacity < 0)
            or input_length is not None and
            (type(input_length) is not int or not 0 <= input_length <= MAX_PARSEABLE_INPUT)):
        return INVALID_RESULT, b""
    if input_is_null or values is None:
        return INVALID_RESULT, b""
    if not isinstance(values, (list, tuple)):
        return INVALID_RESULT, b""
    if input_length is not None and input_length != len(values):
        return INVALID_RESULT, b""
    parsed = _parse(values)
    if parsed is None:
        return INVALID_RESULT, b""
    n, edges = parsed
    edge_ids = {edge: index for index, edge in enumerate(edges)}
    adjacent = [[False] * n for _ in range(n)]
    for u, v in edges:
        adjacent[u][v] = adjacent[v][u] = True
    support = [0] * len(edges)
    for u in range(n):
        for v in range(u + 1, n):
            if not adjacent[u][v]:
                continue
            for w in range(v + 1, n):
                if adjacent[u][w] and adjacent[v][w]:
                    support[edge_ids[u, v]] += 1
                    support[edge_ids[u, w]] += 1
                    support[edge_ids[v, w]] += 1
    alive = [True] * len(edges)
    trussness = [0] * len(edges)
    remaining = len(edges)
    level = 0
    while remaining:
        selected = min((edge for edge in range(len(edges)) if alive[edge]),
                       key=lambda edge: (support[edge], edge))
        level = max(level, support[selected])
        trussness[selected] = level + 2
        alive[selected] = False
        remaining -= 1
        u, v = edges[selected]
        for w in range(n):
            if w in (u, v) or not (adjacent[u][w] and adjacent[v][w]):
                continue
            first = edge_ids[tuple(sorted((u, w)))]
            second = edge_ids[tuple(sorted((v, w)))]
            if alive[first] and alive[second]:
                if support[first] > level:
                    support[first] -= 1
                if support[second] > level:
                    support[second] -= 1
    output = b"".join(struct.pack("<q", value) for value in trussness)
    if output_is_null or output_capacity is not None and output_capacity < len(output):
        return OUTPUT_ERROR, b""
    return len(output), output


def expected_result(values: Sequence[int] | None) -> tuple[int, bytes]:
    return expected_output(values)
