"""Dictionary-state verifier for the bounded weighted-caching Greedy Dual profile."""

from __future__ import annotations

import struct
from collections.abc import Sequence

MAX_REQUESTS = 7
MAX_FILES = 8
MAX_INPUT = 16
MAX_OUTPUT_BYTES = 40


def _parse(values: Sequence[int] | None) -> tuple[int, list[tuple[int, int]]] | None:
    if (not isinstance(values, (list, tuple)) or not 2 <= len(values) <= MAX_INPUT
            or any(type(value) is not int or not -(1 << 63) <= value < (1 << 63)
                   for value in values)):
        return None
    capacity, request_count = values[0], values[1]
    if (not 1 <= capacity <= MAX_FILES or not 0 <= request_count <= MAX_REQUESTS
            or len(values) != 2 + 2 * request_count):
        return None
    requests: list[tuple[int, int]] = []
    metadata: dict[int, int] = {}
    for index in range(request_count):
        page, retrieval_cost = values[2 + 2 * index:4 + 2 * index]
        if not 0 <= page < MAX_FILES or not 0 <= retrieval_cost <= 20:
            return None
        if page in metadata and metadata[page] != retrieval_cost:
            return None
        metadata[page] = retrieval_cost
        requests.append((page, retrieval_cost))
    return capacity, requests


def _simulate(capacity: int, requests: list[tuple[int, int]]) -> list[int]:
    credit_by_page: dict[int, int] = {}
    hit_bits = 0
    eviction_bytes: list[int] = []
    misses = 0
    retrieval_cost = 0
    for time, (page, cost) in enumerate(requests):
        if page in credit_by_page:
            hit_bits |= 1 << time
            credit_by_page[page] = cost  # Greedy Dual resets a hit page to its cost.
            eviction_bytes.append(0)
            continue
        misses += 1
        retrieval_cost += cost
        evicted_pages = set()
        while len(credit_by_page) >= capacity:
            smallest_credit = min(credit_by_page.values())
            adjusted = {resident: credit - smallest_credit
                        for resident, credit in credit_by_page.items()}
            evicted_pages.update(page_id for page_id, credit in adjusted.items() if credit == 0)
            credit_by_page = {page_id: credit for page_id, credit in adjusted.items() if credit > 0}
        eviction_bytes.append(sum(1 << page_id for page_id in evicted_pages))
        credit_by_page[page] = cost
    eviction_signature = sum(mask << (8 * index) for index, mask in enumerate(eviction_bytes))
    resident_mask = sum(1 << page for page in credit_by_page)
    return [misses, retrieval_cost, hit_bits, eviction_signature, resident_mask]


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
