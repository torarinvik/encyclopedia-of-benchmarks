"""Primary oracle for supplied-world greedy rumor protection traces."""

from __future__ import annotations

import struct
from collections.abc import Sequence

MAX_INPUT_LENGTH = 61
MAX_OUTPUT_BYTES = 56


def _infected_count(n: int, sources: list[int], edges: list[tuple[int, int, int]],
                    world: int, protected: set[int]) -> int:
    status = [0] * n  # 0 inactive, 1 infected, 2 protected
    rumor_front = set(sources)
    protector_front = set(protected)
    for vertex in rumor_front:
        status[vertex] = 1
    for vertex in protector_front:
        status[vertex] = 2
    while rumor_front or protector_front:
        rumor_proposals: set[int] = set()
        protector_proposals: set[int] = set()
        for source, target, worlds in edges:
            if status[target] != 0:
                continue
            if source in protector_front:
                protector_proposals.add(target)
            if source in rumor_front and worlds & (1 << world):
                rumor_proposals.add(target)
        next_rumor: set[int] = set()
        next_protector: set[int] = set()
        for target in range(n):
            if status[target] != 0:
                continue
            if target in protector_proposals:
                status[target] = 2
                next_protector.add(target)
            elif target in rumor_proposals:
                status[target] = 1
                next_rumor.add(target)
        rumor_front, protector_front = next_rumor, next_protector
    return status.count(1)


def expected_output(values: Sequence[int] | None, capacity: int | None = None,
                    output_is_null: bool = False, input_is_null: bool = False,
                    input_length: int | None = None) -> tuple[int, bytes]:
    if type(output_is_null) is not bool or type(input_is_null) is not bool:
        return -1, b""
    if capacity is not None and (type(capacity) is not int or capacity < 0):
        return -1, b""
    if input_length is not None and (type(input_length) is not int or not 0 <= input_length <= MAX_INPUT_LENGTH):
        return -1, b""
    if input_is_null or values is None or not isinstance(values, (list, tuple)):
        return -1, b""
    if input_length is not None and input_length != len(values):
        return -1, b""
    if not 5 <= len(values) <= MAX_INPUT_LENGTH or any(type(x) is not int or not -(1 << 63) <= x < (1 << 63) for x in values):
        return -1, b""
    n, m, source_count, k, worlds = values[:5]
    if not 2 <= n <= 8 or not 0 <= m <= 16 or not 1 <= source_count < n or not 1 <= k <= 3 or not 1 <= worlds <= 8:
        return -1, b""
    if k > n - source_count or len(values) != 5 + source_count + 3 * m:
        return -1, b""
    sources = list(values[5:5 + source_count])
    if any(not 0 <= vertex < n for vertex in sources) or len(set(sources)) != source_count:
        return -1, b""
    edges: list[tuple[int, int, int]] = []
    seen: set[tuple[int, int]] = set()
    valid_world_bits = (1 << worlds) - 1
    for edge_index in range(m):
        source, target, live_mask = values[5 + source_count + 3 * edge_index:8 + source_count + 3 * edge_index]
        if not 0 <= source < n or not 0 <= target < n or source == target or not 0 <= live_mask <= valid_world_bits:
            return -1, b""
        if (source, target) in seen:
            return -1, b""
        seen.add((source, target))
        edges.append((source, target, live_mask))

    baseline = [_infected_count(n, sources, edges, world, set()) for world in range(worlds)]
    selected: set[int] = set()
    trace: list[int] = []
    for _ in range(k):
        current = [baseline[w] - _infected_count(n, sources, edges, w, selected) for w in range(worlds)]
        best_node = -1
        best_score = -1
        for candidate in range(n):
            if candidate in sources or candidate in selected:
                continue
            next_set = selected | {candidate}
            score = sum(
                baseline[w] - _infected_count(n, sources, edges, w, next_set) - current[w]
                for w in range(worlds)
            )
            if score > best_score:
                best_score, best_node = score, candidate
        if best_node < 0:
            return -1, b""
        selected.add(best_node)
        trace.extend((best_node, best_score))

    words = [k, *trace]
    payload = b"".join(struct.pack("<q", word) for word in words)
    if output_is_null or capacity is not None and capacity < len(payload):
        return -2, b""
    return len(payload), payload
