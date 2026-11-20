"""Direct triggering-world and queue-reachability reference for bounded LT greedy."""

from __future__ import annotations

import struct
from collections.abc import Sequence

MAX_N = 8
MAX_M = 24
MAX_WORLDS = 8
WEIGHT_SCALE = 256
MAX_VALID_INPUT_LENGTH = 4 + 3 * MAX_M + MAX_N * MAX_WORLDS
MAX_INPUT_LENGTH = MAX_VALID_INPUT_LENGTH + 1
MAX_OUTPUT_BYTES = 8 * (1 + 2 * MAX_N)
WORKSPACE_BYTES = 4096


def _parse(values: Sequence[int]):
    if not 4 <= len(values) <= MAX_INPUT_LENGTH:
        return None
    if any(type(value) is not int or not -(1 << 63) <= value < (1 << 63)
           for value in values):
        return None

    n, edge_count, budget, world_count = values[:4]
    if not 1 <= n <= MAX_N or not 0 <= edge_count <= MAX_M:
        return None
    if not 0 <= budget <= n or not 1 <= world_count <= MAX_WORLDS:
        return None
    required = 4 + 3 * edge_count + n * world_count
    if len(values) != required:
        return None

    edges: list[tuple[int, int, int]] = []
    seen: set[tuple[int, int]] = set()
    incoming = [0] * n
    for edge_id in range(edge_count):
        source, target, weight = values[4 + 3 * edge_id:7 + 3 * edge_id]
        if not 0 <= source < n or not 0 <= target < n or source == target:
            return None
        if not 0 <= weight <= WEIGHT_SCALE or (source, target) in seen:
            return None
        seen.add((source, target))
        incoming[target] += weight
        if incoming[target] > WEIGHT_SCALE:
            return None
        edges.append((source, target, weight))

    draws_start = 4 + 3 * edge_count
    draws: list[list[int]] = []
    for world in range(world_count):
        row = list(values[draws_start + world * n:draws_start + (world + 1) * n])
        if any(not 0 <= draw < WEIGHT_SCALE for draw in row):
            return None
        draws.append(row)
    return n, budget, world_count, edges, draws


def _sample_parents(n: int, edges: list[tuple[int, int, int]], draws: list[int]) -> list[int]:
    parents = [-1] * n
    for target in range(n):
        ticket = draws[target]
        offset = 0
        for source, edge_target, weight in edges:
            if edge_target != target:
                continue
            if offset <= ticket < offset + weight:
                parents[target] = source
                break
            offset += weight
    return parents


def _reachable_count(n: int, parents: list[int], seed_mask: int) -> int:
    reached = seed_mask
    queue = [vertex for vertex in range(n) if seed_mask & (1 << vertex)]
    head = 0
    while head < len(queue):
        source = queue[head]
        head += 1
        for target, parent in enumerate(parents):
            if parent == source and not reached & (1 << target):
                reached |= 1 << target
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
    n, budget, world_count, edges, draws = parsed
    parents = [_sample_parents(n, edges, row) for row in draws]

    selected = 0
    trace: list[int] = []
    for _ in range(budget):
        current = [_reachable_count(n, parents[world], selected)
                   for world in range(world_count)]
        best_node = -1
        best_gain = -1
        for candidate in range(n):
            bit = 1 << candidate
            if selected & bit:
                continue
            gain = sum(
                _reachable_count(n, parents[world], selected | bit) - current[world]
                for world in range(world_count)
            )
            if gain > best_gain:
                best_node, best_gain = candidate, gain
        if best_node < 0:
            return -1, b""
        selected |= 1 << best_node
        trace.extend((best_node, best_gain))

    payload = b"".join(struct.pack("<q", word) for word in (budget, *trace))
    if output_is_null or capacity is not None and capacity < len(payload):
        return -2, b""
    return len(payload), payload
