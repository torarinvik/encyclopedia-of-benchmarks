"""Bounded oracle for the GBBS Yoshida recursive MIS query profile."""

from __future__ import annotations

import struct
from collections.abc import Sequence

MAX_NODES = 12
MAX_EDGES = 24
MAX_QUERY_CUTOFF = 128
MAX_INPUT_LENGTH = 4 + 2 * MAX_EDGES
MAX_OUTPUT_BYTES = 16
INVALID_RESULT = -1
OUTPUT_ERROR = -2
I64_MIN = -(1 << 63)
I64_MAX = (1 << 63) - 1
MASK64 = (1 << 64) - 1


def _hash64(value: int) -> int:
    """ParlayLib's pinned hash64 transform, with explicit uint64 wrapping."""
    mixed = (value * 3935559000370003845 + 2691343689449507681) & MASK64
    mixed ^= mixed >> 21
    mixed ^= (mixed << 37) & MASK64
    mixed ^= mixed >> 4
    mixed = mixed * 4768777513237032717 & MASK64
    mixed ^= (mixed << 20) & MASK64
    mixed ^= mixed >> 41
    mixed ^= (mixed << 5) & MASK64
    return mixed


def _parse(values: Sequence[int] | None):
    if (not isinstance(values, (tuple, list)) or len(values) < 4
            or len(values) > MAX_INPUT_LENGTH
            or any(type(value) is not int or not I64_MIN <= value <= I64_MAX
                   for value in values)):
        return None
    n, m, root, cutoff = values[:4]
    if (not 1 <= n <= MAX_NODES or not 0 <= m <= MAX_EDGES
            or not 0 <= root < n or not 0 <= cutoff <= MAX_QUERY_CUTOFF
            or len(values) != 4 + 2 * m):
        return None
    adjacency = [[] for _ in range(n)]
    seen = set()
    for offset in range(4, len(values), 2):
        left, right = values[offset:offset + 2]
        if not 0 <= left < right < n or (left, right) in seen:
            return None
        seen.add((left, right))
        adjacency[left].append(right)
        adjacency[right].append(left)
    priority = [_hash64(vertex) for vertex in range(n)]
    for neighbors in adjacency:
        neighbors.sort(key=lambda vertex: (priority[vertex], vertex))
    return n, root, cutoff, adjacency, priority


def expected_output(values: Sequence[int] | None, capacity: int | None = None,
                    output_is_null: bool = False, input_is_null: bool = False,
                    input_length: int | None = None) -> tuple[int, bytes]:
    if (type(output_is_null) is not bool or type(input_is_null) is not bool
            or capacity is not None and (type(capacity) is not int or capacity < 0)
            or input_length is not None and (type(input_length) is not int
                                             or not 0 <= input_length <= MAX_INPUT_LENGTH)
            or input_is_null and values not in (None, [], ())
            or not input_is_null and values is not None and input_length is not None
            and input_length != len(values)):
        return INVALID_RESULT, b""
    if input_is_null or values is None:
        return INVALID_RESULT, b""
    parsed = _parse(values)
    if parsed is None:
        return INVALID_RESULT, b""
    _n, root, cutoff, adjacency, priority = parsed
    work = 0

    def query(vertex: int) -> int:
        nonlocal work
        for neighbor in adjacency[vertex]:
            if work == cutoff:
                return -1  # unknown
            work += 1
            if (priority[vertex] < priority[neighbor]
                    or priority[vertex] == priority[neighbor]
                    and vertex <= neighbor):
                break
            status = query(neighbor)
            if status == 1:
                return 0  # out: a lower-priority neighbor is in the MIS
            if status == -1:
                return -1
        return 1  # in

    status = query(root)
    output = struct.pack("<qq", status, work)
    if output_is_null or capacity is not None and capacity < MAX_OUTPUT_BYTES:
        return OUTPUT_ERROR, b""
    return MAX_OUTPUT_BYTES, output
