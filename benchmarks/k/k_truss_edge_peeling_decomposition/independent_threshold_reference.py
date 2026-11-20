"""Independent repeated-threshold reference for edge trussness."""

from __future__ import annotations

import struct
from collections.abc import Sequence

MAX_VERTICES = 16
MAX_EDGES = 120
MAX_PARSEABLE_INPUT = 243
I64_MIN = -(1 << 63)
I64_MAX = (1 << 63) - 1


def expected_output(values: Sequence[int] | None) -> tuple[int, bytes]:
    if (not isinstance(values, (list, tuple)) or len(values) < 2
            or len(values) > MAX_PARSEABLE_INPUT
            or any(type(value) is not int or not I64_MIN <= value <= I64_MAX
                   for value in values)):
        return -1, b""
    n, m = values[:2]
    if not 1 <= n <= MAX_VERTICES or not 0 <= m <= MAX_EDGES or len(values) != 2 + 2 * m:
        return -1, b""
    edges: list[tuple[int, int]] = []
    edge_ids: dict[tuple[int, int], int] = {}
    for index, offset in enumerate(range(2, len(values), 2)):
        u, v = values[offset : offset + 2]
        if not 0 <= u < v < n or (u, v) in edge_ids:
            return -1, b""
        edges.append((u, v))
        edge_ids[u, v] = index

    # For each k, repeatedly remove edges with fewer than k-2 surviving
    # triangles. Every edge left at the fixed point belongs to that k-truss.
    trussness = [2] * m
    for k in range(3, n + 1):
        alive = [True] * m
        changed = True
        while changed:
            changed = False
            support = [0] * m
            for u in range(n):
                for v in range(u + 1, n):
                    first = edge_ids.get((u, v))
                    if first is None or not alive[first]:
                        continue
                    for w in range(v + 1, n):
                        second = edge_ids.get((u, w))
                        third = edge_ids.get((v, w))
                        if (second is not None and third is not None
                                and alive[second] and alive[third]):
                            support[first] += 1
                            support[second] += 1
                            support[third] += 1
            for edge in range(m):
                if alive[edge] and support[edge] < k - 2:
                    alive[edge] = False
                    changed = True
        for edge in range(m):
            if alive[edge]:
                trussness[edge] = k
    output = b"".join(struct.pack("<q", value) for value in trussness)
    return len(output), output
