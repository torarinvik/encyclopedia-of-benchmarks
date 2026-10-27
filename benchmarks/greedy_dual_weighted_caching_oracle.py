"""Weighted-caching Greedy Dual profile with unit-sized files."""

from __future__ import annotations

import struct
from collections.abc import Sequence

MAX_REQUESTS = 7
MAX_FILES = 8
MAX_INPUT = 16
MAX_OUTPUT_BYTES = 40


def _parse(values: Sequence[int] | None) -> tuple[int, list[tuple[int, int]]] | None:
    if (not isinstance(values, (list, tuple)) or len(values) < 2 or len(values) > MAX_INPUT
            or any(type(value) is not int or not -(1 << 63) <= value < (1 << 63)
                   for value in values)):
        return None
    cache_capacity, count = values[:2]
    if (not 1 <= cache_capacity <= MAX_FILES or not 0 <= count <= MAX_REQUESTS
            or len(values) != 2 + 2 * count):
        return None
    requests: list[tuple[int, int]] = []
    known_cost: dict[int, int] = {}
    for request in range(count):
        file_id, cost = values[2 + 2 * request:4 + 2 * request]
        if not 0 <= file_id < MAX_FILES or not 0 <= cost <= 20:
            return None
        if file_id in known_cost and known_cost[file_id] != cost:
            return None
        known_cost[file_id] = cost
        requests.append((file_id, cost))
    return cache_capacity, requests


def _simulate(cache_capacity: int, requests: list[tuple[int, int]]) -> list[int]:
    resident: list[list[int]] = []  # [file_id, credit]
    misses = 0
    total_cost = 0
    hit_flags: list[int] = []
    eviction_masks: list[int] = []
    for file_id, cost in requests:
        position = next((i for i, row in enumerate(resident) if row[0] == file_id), -1)
        if position >= 0:
            hit_flags.append(1)
            eviction_masks.append(0)
            resident[position][1] = cost
            continue
        misses += 1
        total_cost += cost
        evicted = 0
        while len(resident) >= cache_capacity:
            reduction = min(row[1] for row in resident)
            survivors = []
            for row in resident:
                row[1] -= reduction
                if row[1] == 0:
                    evicted |= 1 << row[0]
                else:
                    survivors.append(row)
            resident = survivors
        resident.append([file_id, cost])
        hit_flags.append(0)
        eviction_masks.append(evicted)

    hit_signature = sum(flag << index for index, flag in enumerate(hit_flags))
    eviction_signature = sum(mask << (8 * index) for index, mask in enumerate(eviction_masks))
    resident_mask = sum(1 << row[0] for row in resident)
    return [misses, total_cost, hit_signature, eviction_signature, resident_mask]


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
    cache_capacity, requests = parsed
    payload = b"".join(struct.pack("<q", value) for value in _simulate(cache_capacity, requests))
    if output_is_null or capacity is not None and capacity < len(payload):
        return -2, b""
    return len(payload), payload
