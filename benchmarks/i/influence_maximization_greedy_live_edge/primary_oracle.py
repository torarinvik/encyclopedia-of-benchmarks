"""Primary bounded reference for IC greedy influence maximization."""

from __future__ import annotations

import struct
from collections.abc import Sequence

MAX_N = 8
MAX_M = 24
MAX_WORLDS = 8
MAX_VALID_INPUT_LENGTH = 4 + 3 * MAX_M
MAX_INPUT_LENGTH = MAX_VALID_INPUT_LENGTH + 1
MAX_OUTPUT_BYTES = 8 * (1 + 2 * MAX_N)
WORKSPACE_BYTES = 4096


def _parse(values: Sequence[int]) -> tuple[int, int, int, list[tuple[int, int, int]]] | None:
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
    allowed = (1 << worlds) - 1
    edges: list[tuple[int, int, int]] = []
    seen: set[tuple[int, int]] = set()
    for index in range(m):
        source, target, mask = values[4 + 3 * index:7 + 3 * index]
        if not 0 <= source < n or not 0 <= target < n or source == target:
            return None
        if not 0 <= mask <= allowed or (source, target) in seen:
            return None
        seen.add((source, target))
        edges.append((source, target, mask))
    return n, k, worlds, edges


def _reachable_count(n: int, edges: list[tuple[int, int, int]],
                     world: int, seed_mask: int) -> int:
    reached = seed_mask
    queue = [vertex for vertex in range(n) if seed_mask & (1 << vertex)]
    head = 0
    while head < len(queue):
        source = queue[head]
        head += 1
        for edge_source, target, live_worlds in edges:
            target_bit = 1 << target
            if (edge_source == source and live_worlds & (1 << world)
                    and not reached & target_bit):
                reached |= target_bit
                queue.append(target)
    return reached.bit_count()


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
    n, k, worlds, edges = parsed

    selected = 0
    trace: list[int] = []
    for _ in range(k):
        current = [_reachable_count(n, edges, world, selected)
                   for world in range(worlds)]
        best_node = -1
        best_score = -1
        for candidate in range(n):
            bit = 1 << candidate
            if selected & bit:
                continue
            score = sum(
                _reachable_count(n, edges, world, selected | bit) - current[world]
                for world in range(worlds)
            )
            if score > best_score:
                best_node, best_score = candidate, score
        if best_node < 0:
            return -1, b""
        selected |= 1 << best_node
        trace.extend((best_node, best_score))

    payload = b"".join(struct.pack("<q", word) for word in (k, *trace))
    if output_is_null or capacity is not None and capacity < len(payload):
        return -2, b""
    return len(payload), payload
