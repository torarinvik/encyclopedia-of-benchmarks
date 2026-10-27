"""Bounded reverse-delete profile for DOI 171's simple 2-ECSS heuristic."""
from __future__ import annotations

import struct
from collections.abc import Sequence

MAX_N = 8
MAX_M = 28
MAX_VALID_INPUT_LENGTH = 2 + 2 * MAX_M
MAX_INPUT_LENGTH = MAX_VALID_INPUT_LENGTH + 1
MAX_OUTPUT_BYTES = 8 * (1 + 2 * MAX_M)


def _connected(n: int, edges: list[tuple[int, int]], active: list[bool], skip: int = -1) -> bool:
    seen = [False] * n
    queue = [0]
    seen[0] = True
    for u in queue:
        for i, (a, b) in enumerate(edges):
            if not active[i] or i == skip:
                continue
            v = b if a == u else a if b == u else -1
            if v >= 0 and not seen[v]:
                seen[v] = True
                queue.append(v)
    return all(seen)


def _two_edge_connected(n: int, edges: list[tuple[int, int]], active: list[bool]) -> bool:
    if not _connected(n, edges, active):
        return False
    return all(_connected(n, edges, active, i) for i, on in enumerate(active) if on)


def expected_output(values: Sequence[int] | None, capacity: int | None = None,
                    output_is_null: bool = False, input_is_null: bool = False,
                    input_length: int | None = None) -> tuple[int, bytes]:
    if (type(output_is_null) is not bool or type(input_is_null) is not bool
            or capacity is not None and (type(capacity) is not int or capacity < 0)
            or input_length is not None and (type(input_length) is not int or input_length < 0)
            or input_is_null and values not in (None, [], ())
            or not input_is_null and values is not None and input_length is not None
            and input_length != len(values)):
        return -1, b""
    if input_is_null or values is None or not isinstance(values, (list, tuple)):
        return -1, b""
    if len(values) < 2 or len(values) > MAX_INPUT_LENGTH or any(
            type(x) is not int or not -(1 << 63) <= x < (1 << 63) for x in values):
        return -1, b""
    n, m = values[:2]
    if not 3 <= n <= MAX_N or not 3 <= m <= MAX_M or len(values) != 2 + 2 * m:
        return -1, b""
    edges: list[tuple[int, int]] = []
    present: set[tuple[int, int]] = set()
    for i in range(m):
        u, v = values[2 + 2*i:4 + 2*i]
        if not 0 <= u < v < n or (u, v) in present:
            return -1, b""
        present.add((u, v))
        edges.append((u, v))
    active = [True] * m
    if not _two_edge_connected(n, edges, active):
        return -1, b""
    # The input sequence is the fixed order in which the source's heuristic
    # considers edges. A deletion is committed exactly when 2-edge-connectivity
    # remains, i.e. the graph stays connected after deletion of any one edge.
    for i in range(m):
        active[i] = False
        if not _two_edge_connected(n, edges, active):
            active[i] = True
    kept = sorted(edges[i] for i in range(m) if active[i])
    flat = (len(kept), *(x for edge in kept for x in edge))
    output = b"".join(struct.pack("<q", x) for x in flat)
    if output_is_null or capacity is not None and capacity < len(output):
        return -2, b""
    return len(output), output
