"""Direct table-query oracle for the far-query transit-node routing branch."""

from __future__ import annotations

import struct
from collections.abc import Sequence

MAX_INPUT_LENGTH = 86
MAX_OUTPUT_BYTES = 24


def expected_output(values: Sequence[int] | None, capacity: int | None = None,
                    output_is_null: bool = False, input_is_null: bool = False,
                    input_length: int | None = None) -> tuple[int, bytes]:
    if (type(output_is_null) is not bool or type(input_is_null) is not bool or
            capacity is not None and (type(capacity) is not int or capacity < 0) or
            input_length is not None and (type(input_length) is not int or not 0 <= input_length <= MAX_INPUT_LENGTH)):
        return -1, b""
    if input_is_null or values is None or not isinstance(values, (list, tuple)):
        return -1, b""
    if input_length is not None and input_length != len(values):
        return -1, b""
    if not 7 <= len(values) <= MAX_INPUT_LENGTH or any(type(x) is not int or not -(1 << 63) <= x < (1 << 63) for x in values):
        return -1, b""
    q, source, target, far = values[:4]
    if not 1 <= q <= 8 or not 0 <= source < 32 or not 0 <= target < 32 or far != 1:
        return -1, b""
    at = 4
    fcount = values[at]; at += 1
    if not 1 <= fcount <= min(q, 4) or at + 2 * fcount > len(values):
        return -1, b""
    forward: list[tuple[int, int]] = []
    for _ in range(fcount):
        node, distance = values[at], values[at + 1]; at += 2
        if not 0 <= node < q or not 0 <= distance <= 1_000_000 or any(node == u for u, _ in forward):
            return -1, b""
        forward.append((node, distance))
    if at >= len(values): return -1, b""
    bcount = values[at]; at += 1
    if not 1 <= bcount <= min(q, 4) or at + 2 * bcount > len(values):
        return -1, b""
    backward: list[tuple[int, int]] = []
    for _ in range(bcount):
        node, distance = values[at], values[at + 1]; at += 2
        if not 0 <= node < q or not 0 <= distance <= 1_000_000 or any(node == v for v, _ in backward):
            return -1, b""
        backward.append((node, distance))
    if at + q * q != len(values): return -1, b""
    table = values[at:]
    if any(not 0 <= d <= 1_000_000 for d in table): return -1, b""
    if any(table[i * q + i] != 0 for i in range(q)): return -1, b""
    best: tuple[int, int, int] | None = None
    for u, ds in forward:
        for v, dt in backward:
            candidate = (ds + table[u * q + v] + dt, u, v)
            if best is None or candidate < best: best = candidate
    assert best is not None
    payload = b"".join(struct.pack("<q", x) for x in best)
    if output_is_null or capacity is not None and capacity < 24:
        return -2, b""
    return 24, payload
