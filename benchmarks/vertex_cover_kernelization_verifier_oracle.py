"""Independent exact verifier using adjacency bitmasks and restart passes."""

from __future__ import annotations

import struct
from collections.abc import Sequence

MAX_INPUT = 131


def expected_output(values: Sequence[int] | None, capacity: int | None = None,
                    output_is_null: bool = False, input_is_null: bool = False,
                    input_length: int | None = None) -> tuple[int, bytes]:
    if (type(output_is_null) is not bool or type(input_is_null) is not bool
            or capacity is not None and (type(capacity) is not int or capacity < 0)
            or input_length is not None and (type(input_length) is not int or not 0 <= input_length <= MAX_INPUT)
            or input_is_null and values not in (None, [], ())
            or not input_is_null and values is not None and input_length is not None and input_length != len(values)):
        return -1, b""
    if input_is_null or values is None or not isinstance(values, (list, tuple)):
        return -1, b""
    if len(values) < 3 or len(values) > MAX_INPUT or any(type(x) is not int or not -(1 << 63) <= x < (1 << 63) for x in values):
        return -1, b""
    n, m, residual_k = values[:3]
    if not 1 <= n <= 16 or not 0 <= m <= 64 or not 0 <= residual_k <= 16 or len(values) != 3 + 2*m:
        return -1, b""
    masks = [0] * n
    prior_u = prior_v = -1
    for edge_index in range(m):
        u, v = values[3+2*edge_index:5+2*edge_index]
        if not 0 <= u < v < n or u < prior_u or (u == prior_u and v <= prior_v):
            return -1, b""
        masks[u] |= 1 << v
        masks[v] |= 1 << u
        prior_u, prior_v = u, v

    all_vertices = (1 << n) - 1
    alive = all_vertices
    chosen_mask = 0
    impossible = False
    while True:
        if residual_k < 0:
            impossible = True
            break
        reduced = False
        for u in range(n):
            if alive >> u & 1 and (masks[u] & alive) == 0:
                alive &= ~(1 << u)
                reduced = True
                break
        if reduced:
            continue
        leaf = None
        for u in range(n):
            if not (alive >> u & 1):
                continue
            neighborhood = masks[u] & alive
            if neighborhood.bit_count() == 1:
                leaf = (u, (neighborhood & -neighborhood).bit_length() - 1)
                break
        if leaf is not None:
            take = leaf[1]
        else:
            take = None
            for u in range(n):
                if alive >> u & 1 and (masks[u] & alive).bit_count() > residual_k:
                    take = u
                    break
            if take is None:
                break
        chosen_mask |= 1 << take
        alive &= ~(1 << take)
        residual_k -= 1

    reduced_edges = []
    for u in range(n):
        if alive >> u & 1:
            for v in range(u+1, n):
                if alive >> v & 1 and masks[u] >> v & 1:
                    reduced_edges.append((u, v))
    fields = [0 if impossible else 1, residual_k, chosen_mask, alive, len(reduced_edges)]
    for u, v in reduced_edges:
        fields.extend((u, v))
    payload = b"".join(struct.pack("<q", field) for field in fields)
    if output_is_null or capacity is not None and capacity < len(payload):
        return -2, b""
    return len(payload), payload
