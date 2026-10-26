"""Independent leaf-set verifier for non-shared edge distance."""

from __future__ import annotations

import struct
from collections.abc import Sequence

MAX_LEAVES = 8
MAX_INPUT = 27


def _leaf_sets(raw: Sequence[int], n: int) -> list[frozenset[int]] | None:
    edge_count = 2 * n - 3
    full = frozenset(range(n))
    expected = {frozenset((leaf,)) for leaf in range(1, n)} | {frozenset((0,))}
    partitions: list[frozenset[int]] = []
    for mask in raw:
        if type(mask) is not int or mask <= 0 or mask >= (1 << n) or mask & 1:
            return None
        side = frozenset(leaf for leaf in range(n) if mask & (1 << leaf))
        # The stored side omits taxon zero, so its complement is its canonical
        # leaf-set representation for the one edge incident to taxon zero.
        if len(side) == n - 1:
            side = full - side
        partitions.append(side)
    if len(partitions) != edge_count or len(set(partitions)) != edge_count:
        return None
    if not expected.issubset(set(partitions)):
        return None
    internal = [part for part in partitions if 2 <= len(part) <= n - 2]
    if len(internal) != n - 3:
        return None
    for i, a in enumerate(internal):
        for b in internal[i + 1:]:
            if a & b and a != b and not a.issubset(b) and not b.issubset(a):
                return None
    return partitions


def _parse(values: Sequence[int] | None) -> tuple[list[frozenset[int]], list[frozenset[int]], int] | None:
    if (not isinstance(values, (list, tuple)) or not 7 <= len(values) <= MAX_INPUT
            or any(type(v) is not int or not -(1 << 63) <= v < (1 << 63) for v in values)):
        return None
    n = values[0]
    if not 3 <= n <= MAX_LEAVES:
        return None
    edges = 2 * n - 3
    if len(values) != 1 + 2 * edges:
        return None
    left = _leaf_sets(values[1:1 + edges], n)
    right = _leaf_sets(values[1 + edges:], n)
    if left is None or right is None:
        return None
    return left, right, edges


def expected_output(values: Sequence[int] | None, capacity: int | None = None,
                    output_is_null: bool = False, input_is_null: bool = False,
                    input_length: int | None = None) -> tuple[int, bytes]:
    if (type(output_is_null) is not bool or type(input_is_null) is not bool
            or capacity is not None and (type(capacity) is not int or capacity < 0)
            or input_length is not None and (type(input_length) is not int
                                             or not 0 <= input_length <= MAX_INPUT)
            or input_is_null and values not in (None, [], ())
            or not input_is_null and values is not None and input_length is not None
            and input_length != len(values)):
        return -1, b""
    if input_is_null or values is None:
        return -1, b""
    parsed = _parse(values)
    if parsed is None:
        return -1, b""
    left, right, edge_count = parsed
    shared = sum(1 for split in left if split in set(right))
    payload = struct.pack("<q", edge_count - shared)
    if output_is_null or capacity is not None and capacity < 8:
        return -2, b""
    return 8, payload
