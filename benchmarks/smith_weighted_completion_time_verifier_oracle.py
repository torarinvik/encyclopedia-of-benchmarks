"""Independent subset-DP optimality verifier for Smith's rule."""

from __future__ import annotations

import struct
from collections.abc import Sequence

MAX_N = 12
MAX_INPUT = 25


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
    n = values[0]
    if not 1 <= n <= MAX_N or len(values) != 1 + 2*n:
        return -1, b""
    processing = [values[1 + 2*i] for i in range(n)]
    weight = [values[2 + 2*i] for i in range(n)]
    if any(not 1 <= p <= 10000 for p in processing) or any(not 1 <= w <= 10000 for w in weight):
        return -1, b""

    full = (1 << n) - 1
    dp = [0] * (full + 1)
    for mask in range(full - 1, -1, -1):
        elapsed = sum(processing[j] for j in range(n) if mask & (1 << j))
        best = None
        for j in range(n):
            if not mask & (1 << j):
                candidate = weight[j] * (elapsed + processing[j]) + dp[mask | (1 << j)]
                if best is None or candidate < best:
                    best = candidate
        dp[mask] = 0 if best is None else best
    order = []
    mask = 0
    while mask != full:
        elapsed = sum(processing[j] for j in range(n) if mask & (1 << j))
        target = dp[mask]
        for j in range(n):
            if mask & (1 << j):
                continue
            candidate = weight[j] * (elapsed + processing[j]) + dp[mask | (1 << j)]
            if candidate == target:
                order.append(j)
                mask |= 1 << j
                break
    output = b"".join(struct.pack("<q", x) for x in (dp[0], *order))
    if output_is_null or capacity is not None and capacity < len(output):
        return -2, b""
    return len(output), output
