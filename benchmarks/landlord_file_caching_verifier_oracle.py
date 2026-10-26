"""Fraction-based independent verifier for Landlord file caching."""

from __future__ import annotations

import struct
from collections.abc import Sequence
from fractions import Fraction

MAX_REQUESTS = 7
MAX_FILES = 8
MAX_INPUT = 23


def _valid_input(data: Sequence[int] | None) -> tuple[int, list[tuple[int, int, int]]] | None:
    if (not isinstance(data, (tuple, list)) or len(data) < 2 or len(data) > MAX_INPUT
            or any(type(x) is not int or not -(1 << 63) <= x < (1 << 63) for x in data)):
        return None
    room, count = data[0], data[1]
    if room not in range(1, 9) or count not in range(MAX_REQUESTS + 1) or len(data) != 2 + 3 * count:
        return None
    requests = []
    known = {}
    for position in range(count):
        ident, size, retrieval = data[2 + 3 * position:5 + 3 * position]
        if ident not in range(MAX_FILES) or size not in range(1, min(4, room) + 1) or retrieval not in range(21):
            return None
        if ident in known and known[ident] != (size, retrieval):
            return None
        known[ident] = (size, retrieval)
        requests.append((ident, size, retrieval))
    return room, requests


def _fraction_trace(room: int, requests: list[tuple[int, int, int]]) -> list[int]:
    # Map file IDs to (size, exact rational credit).
    cache: dict[int, tuple[int, Fraction]] = {}
    hits: list[int] = []
    evictions: list[int] = []
    misses = 0
    paid = 0
    for ident, size, retrieval in requests:
        if ident in cache:
            hits.append(1)
            evictions.append(0)
            continue
        misses += 1
        paid += retrieval
        eviction_mask = 0
        while sum(entry[0] for entry in cache.values()) + size > room:
            reduction = min(credit / file_size for file_size, credit in cache.values())
            updated = {key: (file_size, credit - reduction * file_size)
                       for key, (file_size, credit) in cache.items()}
            cache = {key: entry for key, entry in updated.items() if entry[1] != 0}
            for key, entry in updated.items():
                if entry[1] == 0:
                    eviction_mask |= 1 << key
        cache[ident] = (size, Fraction(retrieval))
        hits.append(0)
        evictions.append(eviction_mask)
    resident_mask = sum(1 << ident for ident in cache)
    hit_signature = sum(flag << index for index, flag in enumerate(hits))
    eviction_signature = sum(mask << (8 * index) for index, mask in enumerate(evictions))
    return [misses, paid, hit_signature, eviction_signature, resident_mask]


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
    parsed = _valid_input(values)
    if parsed is None:
        return -1, b""
    room, requests = parsed
    result = _fraction_trace(room, requests)
    payload = b"".join(struct.pack("<q", value) for value in result)
    if output_is_null or capacity is not None and capacity < len(payload):
        return -2, b""
    return len(payload), payload
