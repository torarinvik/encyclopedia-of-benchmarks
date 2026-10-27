"""Independent full-cycle verifier for sampled-Ψ suffix-array access."""

from __future__ import annotations

import struct
from collections.abc import Sequence

MAX_N = 32
MAX_INPUT_LENGTH = 3 + 2 * MAX_N
MAX_OUTPUT_BYTES = 16
MAX_WORKSPACE_BYTES = 1024


def verify(values: Sequence[int] | None) -> tuple[int, bytes]:
    if (not isinstance(values, (list, tuple)) or not 5 <= len(values) <= MAX_INPUT_LENGTH
            or any(type(value) is not int or not -(1 << 63) <= value < (1 << 63)
                   for value in values)):
        return -1, b""
    n, query, stride = values[:3]
    if not 1 <= n <= MAX_N or not 0 <= query < n or not 1 <= stride <= n or len(values) != 3 + 2 * n:
        return -1, b""
    psi = values[3:3 + n]
    sample_by_rank = values[3 + n:]
    if any(not 0 <= rank < n for rank in psi) or len(set(psi)) != n:
        return -1, b""
    if any(not 0 <= sample <= n for sample in sample_by_rank):
        return -1, b""

    # Reconstruct A around the Ψ cycle from the first supplied sample. This
    # check is independent of the query's sampled-walk arithmetic.
    anchor = -1
    for rank, sample in enumerate(sample_by_rank):
        if sample != 0:
            anchor = rank
            break
    if anchor < 0:
        return -1, b""
    value = sample_by_rank[anchor]
    if (value - 1) % stride != 0:
        return -1, b""
    full_sa = [0] * n
    visited = set()
    rank = anchor
    for _ in range(n):
        if rank in visited:
            return -1, b""
        visited.add(rank)
        full_sa[rank] = value
        rank = psi[rank]
        value = value % n + 1
    if rank != anchor or len(visited) != n or value != sample_by_rank[anchor]:
        return -1, b""
    if set(full_sa) != set(range(1, n + 1)):
        return -1, b""
    for index, sa_value in enumerate(full_sa):
        if sample_by_rank[index] != (sa_value if (sa_value - 1) % stride == 0 else 0):
            return -1, b""

    rank = query
    hops = 0
    while sample_by_rank[rank] == 0:
        rank = psi[rank]
        hops += 1
        if hops >= stride:
            return -1, b""  # unreachable for the profile's periodic sample phase
    return 16, struct.pack("<QQ", full_sa[query], hops)
