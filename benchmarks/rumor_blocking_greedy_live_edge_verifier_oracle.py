"""Independent oracle using per-world frontier masks for the cascade trace."""

from __future__ import annotations

import struct
from collections.abc import Sequence

MAX_INPUT_LENGTH = 61


def _infected_count(n: int, sources: tuple[int, ...], edges: tuple[tuple[int, int, int], ...],
                    world: int, protectors: int) -> int:
    infected = 0
    protected = protectors
    for source in sources:
        infected |= 1 << source
    rumor_front = infected
    protector_front = protected
    while rumor_front or protector_front:
        rumor_next = 0
        protector_next = 0
        for source, target, live_worlds in edges:
            target_bit = 1 << target
            if (infected | protected) & target_bit:
                continue
            if protector_front & (1 << source):
                protector_next |= target_bit
            if rumor_front & (1 << source) and live_worlds & (1 << world):
                rumor_next |= target_bit
        newly_protected = protector_next & ~(infected | protected)
        newly_infected = rumor_next & ~(infected | protected | newly_protected)
        protected |= newly_protected
        infected |= newly_infected
        rumor_front = newly_infected
        protector_front = newly_protected
    return infected.bit_count()


def expected_output(values: Sequence[int] | None, capacity: int | None = None,
                    output_is_null: bool = False, input_is_null: bool = False,
                    input_length: int | None = None) -> tuple[int, bytes]:
    if type(output_is_null) is not bool or type(input_is_null) is not bool:
        return -1, b""
    if capacity is not None and (type(capacity) is not int or capacity < 0):
        return -1, b""
    if input_length is not None and (type(input_length) is not int or not 0 <= input_length <= MAX_INPUT_LENGTH):
        return -1, b""
    if input_is_null or not isinstance(values, (list, tuple)):
        return -1, b""
    if input_length is not None and len(values) != input_length:
        return -1, b""
    if not 5 <= len(values) <= MAX_INPUT_LENGTH or any(type(x) is not int or not -(1 << 63) <= x < (1 << 63) for x in values):
        return -1, b""
    n, m, source_count, k, worlds = values[:5]
    if not 2 <= n <= 8 or not 0 <= m <= 16 or not 1 <= source_count < n or not 1 <= k <= 3 or not 1 <= worlds <= 8:
        return -1, b""
    if k > n - source_count or len(values) != 5 + source_count + 3 * m:
        return -1, b""
    sources = tuple(values[5:5 + source_count])
    if len(set(sources)) != source_count or any(not 0 <= x < n for x in sources):
        return -1, b""
    edges = tuple(tuple(values[5 + source_count + 3 * i:8 + source_count + 3 * i]) for i in range(m))
    seen: set[tuple[int, int]] = set()
    world_limit = (1 << worlds) - 1
    for u, v, mask in edges:
        if not 0 <= u < n or not 0 <= v < n or u == v or not 0 <= mask <= world_limit or (u, v) in seen:
            return -1, b""
        seen.add((u, v))

    baseline = [_infected_count(n, sources, edges, w, 0) for w in range(worlds)]
    selected_mask = 0
    trace: list[int] = []
    source_set = set(sources)
    for _ in range(k):
        current = [baseline[w] - _infected_count(n, sources, edges, w, selected_mask) for w in range(worlds)]
        best_node = -1
        best_score = -1
        for node in range(n):
            bit = 1 << node
            if node in source_set or selected_mask & bit:
                continue
            score = 0
            for w in range(worlds):
                score += baseline[w] - _infected_count(n, sources, edges, w, selected_mask | bit) - current[w]
            if score > best_score:
                best_node, best_score = node, score
        if best_node < 0:
            return -1, b""
        selected_mask |= 1 << best_node
        trace.extend((best_node, best_score))
    payload = b"".join(struct.pack("<q", value) for value in (k, *trace))
    if output_is_null or capacity is not None and capacity < len(payload):
        return -2, b""
    return len(payload), payload
