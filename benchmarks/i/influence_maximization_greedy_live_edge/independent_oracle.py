"""Independent closure-based reference for IC influence-greedy traces."""

from __future__ import annotations

import struct
from collections.abc import Sequence

MAX_N = 8
MAX_M = 24
MAX_WORLDS = 8
MAX_VALID_INPUT_LENGTH = 4 + 3 * MAX_M
MAX_INPUT_LENGTH = MAX_VALID_INPUT_LENGTH + 1
MAX_OUTPUT_BYTES = 8 * (1 + 2 * MAX_N)


def _parse(values: Sequence[int]):
    if not 4 <= len(values) <= MAX_INPUT_LENGTH:
        return None
    if any(type(value) is not int or not -(1 << 63) <= value < (1 << 63)
           for value in values):
        return None
    n, m, k, worlds = values[:4]
    if not 1 <= n <= MAX_N or not 0 <= m <= MAX_M:
        return None
    if not 0 <= k <= n or not 1 <= worlds <= MAX_WORLDS:
        return None
    if len(values) != 4 + 3 * m:
        return None
    limit = (1 << worlds) - 1
    arcs: list[tuple[int, int, int]] = []
    seen: set[tuple[int, int]] = set()
    for i in range(m):
        u, v, mask = values[4 + 3 * i:7 + 3 * i]
        if not 0 <= u < n or not 0 <= v < n or u == v:
            return None
        if not 0 <= mask <= limit or (u, v) in seen:
            return None
        seen.add((u, v))
        arcs.append((u, v, mask))
    return n, k, worlds, arcs


def _closure(n: int, arcs: list[tuple[int, int, int]], world: int) -> list[list[bool]]:
    reach = [[source == target for target in range(n)] for source in range(n)]
    for source, target, masks in arcs:
        if masks & (1 << world):
            reach[source][target] = True
    for middle in range(n):
        for source in range(n):
            if reach[source][middle]:
                for target in range(n):
                    reach[source][target] = (
                        reach[source][target] or reach[middle][target]
                    )
    return reach


def _union_size(reach: list[list[bool]], seed_mask: int) -> int:
    count = 0
    for target in range(len(reach)):
        if any(seed_mask & (1 << source) and reach[source][target]
               for source in range(len(reach))):
            count += 1
    return count


def expected_output(values: Sequence[int] | None, capacity: int | None = None,
                    output_is_null: bool = False, input_is_null: bool = False,
                    input_length: int | None = None) -> tuple[int, bytes]:
    if type(output_is_null) is not bool or type(input_is_null) is not bool:
        return -1, b""
    if capacity is not None and (type(capacity) is not int or capacity < 0):
        return -1, b""
    if input_length is not None and (
            type(input_length) is not int or not 0 <= input_length <= MAX_INPUT_LENGTH):
        return -1, b""
    if input_is_null or values is None or not isinstance(values, (list, tuple)):
        return -1, b""
    if input_length is not None and input_length != len(values):
        return -1, b""
    parsed = _parse(values)
    if parsed is None:
        return -1, b""
    n, k, worlds, arcs = parsed
    closures = [_closure(n, arcs, world) for world in range(worlds)]

    chosen_mask = 0
    trace: list[int] = []
    for _ in range(k):
        old_sizes = [_union_size(closure, chosen_mask) for closure in closures]
        best_id = -1
        best_gain = -1
        for candidate in range(n):
            candidate_bit = 1 << candidate
            if chosen_mask & candidate_bit:
                continue
            gain = 0
            for world, closure in enumerate(closures):
                gain += (_union_size(closure, chosen_mask | candidate_bit)
                         - old_sizes[world])
            if gain > best_gain:
                best_id, best_gain = candidate, gain
        if best_id < 0:
            return -1, b""
        chosen_mask |= 1 << best_id
        trace.extend((best_id, best_gain))

    payload = b"".join(struct.pack("<q", word) for word in (k, *trace))
    if output_is_null or capacity is not None and capacity < len(payload):
        return -2, b""
    return len(payload), payload
