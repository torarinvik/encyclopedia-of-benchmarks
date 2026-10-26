"""Integer-scaled Landlord file-caching profile oracle."""

from __future__ import annotations

import struct
from collections.abc import Sequence

MAX_REQUESTS = 7
MAX_FILES = 8
MAX_INPUT = 23
MAX_OUTPUT_BYTES = 40
CREDIT_SCALE = 12  # lcm(1, 2, 3, 4), exact for the allowed file sizes.


def _parse(values: Sequence[int] | None) -> tuple[int, list[tuple[int, int, int]]] | None:
    if (not isinstance(values, (list, tuple)) or len(values) < 2 or len(values) > MAX_INPUT
            or any(type(value) is not int or not -(1 << 63) <= value < (1 << 63)
                   for value in values)):
        return None
    capacity, count = values[:2]
    if not 1 <= capacity <= 8 or not 0 <= count <= MAX_REQUESTS or len(values) != 2 + 3 * count:
        return None
    requests: list[tuple[int, int, int]] = []
    metadata: dict[int, tuple[int, int]] = {}
    for index in range(count):
        file_id, size, cost = values[2 + 3 * index:5 + 3 * index]
        if not 0 <= file_id < MAX_FILES or not 1 <= size <= min(4, capacity) or not 0 <= cost <= 20:
            return None
        if file_id in metadata and metadata[file_id] != (size, cost):
            return None
        metadata[file_id] = (size, cost)
        requests.append((file_id, size, cost))
    return capacity, requests


def _simulate(capacity: int, requests: list[tuple[int, int, int]]) -> list[int]:
    # Resident rows are [file_id, size, scaled credit].
    resident: list[list[int]] = []
    hit_flags: list[int] = []
    eviction_masks: list[int] = []
    misses = 0
    total_cost = 0
    for file_id, size, cost in requests:
        existing = next((row for row in resident if row[0] == file_id), None)
        if existing is not None:
            hit_flags.append(1)
            eviction_masks.append(0)
            continue  # The selected Landlord profile leaves hit credits unchanged.
        misses += 1
        total_cost += cost
        evicted_mask = 0
        while sum(row[1] for row in resident) + size > capacity:
            delta = min(row[2] // row[1] for row in resident)
            for row in resident:
                row[2] -= delta * row[1]
            survivors = []
            for row in resident:
                if row[2] == 0:
                    evicted_mask |= 1 << row[0]
                else:
                    survivors.append(row)
            resident = survivors
        resident.append([file_id, size, cost * CREDIT_SCALE])
        hit_flags.append(0)
        eviction_masks.append(evicted_mask)

    resident_mask = sum(1 << row[0] for row in resident)
    hit_signature = sum(flag << index for index, flag in enumerate(hit_flags))
    eviction_signature = sum(mask << (8 * index) for index, mask in enumerate(eviction_masks))
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
    result = _simulate(cache_capacity, requests)
    payload = b"".join(struct.pack("<q", field) for field in result)
    if output_is_null or capacity is not None and capacity < len(payload):
        return -2, b""
    return len(payload), payload
