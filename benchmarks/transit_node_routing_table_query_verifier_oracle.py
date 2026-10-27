"""Independent enumerative verifier for transit-node distance-table queries."""

from __future__ import annotations

import struct
from collections.abc import Sequence

MAX_INPUT_LENGTH = 86


def expected_output(values: Sequence[int] | None, capacity: int | None = None,
                    output_is_null: bool = False, input_is_null: bool = False,
                    input_length: int | None = None) -> tuple[int, bytes]:
    if type(output_is_null) is not bool or type(input_is_null) is not bool:
        return -1, b""
    if capacity is not None and (type(capacity) is not int or capacity < 0): return -1, b""
    if input_length is not None and (type(input_length) is not int or not 0 <= input_length <= MAX_INPUT_LENGTH): return -1, b""
    if input_is_null or not isinstance(values, (list, tuple)): return -1, b""
    if input_length is not None and input_length != len(values): return -1, b""
    if not 7 <= len(values) <= MAX_INPUT_LENGTH or any(type(x) is not int or not -(1 << 63) <= x < (1 << 63) for x in values): return -1, b""
    q, source, target, far = values[0], values[1], values[2], values[3]
    if q < 1 or q > 8 or source < 0 or source >= 32 or target < 0 or target >= 32 or far != 1: return -1, b""
    pos = 4
    nf = values[pos]; pos += 1
    if nf < 1 or nf > min(q, 4) or pos + 2 * nf > len(values): return -1, b""
    fwd = []
    used = set()
    for _ in range(nf):
        u, d = values[pos], values[pos + 1]; pos += 2
        if u < 0 or u >= q or d < 0 or d > 1_000_000 or u in used: return -1, b""
        used.add(u); fwd.append((u, d))
    if pos >= len(values): return -1, b""
    nb = values[pos]; pos += 1
    if nb < 1 or nb > min(q, 4) or pos + 2 * nb > len(values): return -1, b""
    bwd = []; used.clear()
    for _ in range(nb):
        v, d = values[pos], values[pos + 1]; pos += 2
        if v < 0 or v >= q or d < 0 or d > 1_000_000 or v in used: return -1, b""
        used.add(v); bwd.append((v, d))
    if pos + q*q != len(values): return -1, b""
    table = values[pos:]
    if any(x < 0 or x > 1_000_000 for x in table) or any(table[i*q+i] != 0 for i in range(q)): return -1, b""
    candidates = sorted((ds + table[u*q+v] + dt, u, v) for u, ds in fwd for v, dt in bwd)
    payload = b"".join(struct.pack("<q", x) for x in candidates[0])
    if output_is_null or capacity is not None and capacity < 24: return -2, b""
    return 24, payload
