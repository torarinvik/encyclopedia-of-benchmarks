"""Queue-based deterministic linear-threshold spread reference."""

from __future__ import annotations

import struct
from collections.abc import Sequence

MAX_N = 8
MAX_M = 24
MAX_VALID_INPUT = 91
MAX_PARSEABLE_INPUT = 92
MAX_OUTPUT_BYTES = 80
WORKSPACE_BYTES = 2048


def _parse(values: Sequence[int] | None, input_is_null: bool,
           input_length: int | None):
    if (input_is_null or not isinstance(values, (list, tuple)) or len(values) < 3
            or len(values) > MAX_PARSEABLE_INPUT
            or (input_length is not None and
                (type(input_length) is not int or input_length != len(values)))
            or any(type(value) is not int or not -(1 << 63) <= value < (1 << 63)
                   for value in values)):
        return None
    n, m, seed_count = values[:3]
    if not 1 <= n <= MAX_N or not 0 <= m <= MAX_M or not 0 <= seed_count <= n:
        return None
    expected_length = 3 + seed_count + 3 * m + n
    if len(values) != expected_length:
        return None
    offset = 3
    seeds = list(values[offset:offset + seed_count])
    offset += seed_count
    if any(not 0 <= seed < n for seed in seeds) or len(set(seeds)) != seed_count:
        return None
    edges: list[tuple[int, int, int]] = []
    seen: set[tuple[int, int]] = set()
    incoming = [0] * n
    for _ in range(m):
        source, target, weight = values[offset:offset + 3]
        offset += 3
        if (not 0 <= source < n or not 0 <= target < n or source == target
                or not 0 <= weight <= 16 or (source, target) in seen):
            return None
        seen.add((source, target))
        incoming[target] += weight
        if incoming[target] > 16:
            return None
        edges.append((source, target, weight))
    thresholds = list(values[offset:offset + n])
    if any(not 1 <= threshold <= 16 for threshold in thresholds):
        return None
    return n, seeds, edges, thresholds


def expected_output(values: Sequence[int] | None, capacity: int | None = None,
                    output_is_null: bool = False, input_is_null: bool = False,
                    input_length: int | None = None) -> tuple[int, bytes]:
    if type(output_is_null) is not bool or type(input_is_null) is not bool:
        return -1, b""
    parsed = _parse(values, input_is_null, input_length)
    if parsed is None:
        return -1, b""
    n, seeds, edges, thresholds = parsed

    activation_round = [-1] * n
    frontier = list(seeds)
    for seed in seeds:
        activation_round[seed] = 0
    accumulated = [0] * n
    wave_count = 0
    while frontier:
        following: list[int] = []
        for source in frontier:
            for tail, target, weight in edges:
                if tail != source or activation_round[target] >= 0:
                    continue
                accumulated[target] += weight
                if accumulated[target] >= thresholds[target]:
                    activation_round[target] = wave_count + 1
                    following.append(target)
        frontier = following
        if frontier:
            wave_count += 1

    words = [n, wave_count, *activation_round]
    payload = struct.pack("<" + "q" * len(words), *words)
    if capacity is not None and (type(capacity) is not int or capacity < 0):
        return -1, b""
    if output_is_null or capacity is not None and capacity < len(payload):
        return -2, b""
    return len(payload), payload
