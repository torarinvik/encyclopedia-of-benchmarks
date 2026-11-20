"""Next-use-table oracle for Belady's offline paging rule."""
from __future__ import annotations

from collections.abc import Sequence

MAX_CAPACITY = 8
MAX_REQUESTS = 64
PAGE_COUNT = 16
MAX_VALID_INPUT_LENGTH = 2 + MAX_REQUESTS
MAX_PARSEABLE_INPUT_LENGTH = MAX_VALID_INPUT_LENGTH + 1
CHECKSUM_RADIX = 33_281
MAX_EVICTION_CHECKSUM = 33_280
MAX_RESULT = MAX_REQUESTS * CHECKSUM_RADIX + MAX_EVICTION_CHECKSUM
WORKSPACE_BYTES = 16_384


def _parse(values: Sequence[int] | None, input_is_null: bool = False,
           input_length: int | None = None) -> tuple[int, tuple[int, ...]] | None:
    if (type(input_is_null) is not bool or input_is_null
            or not isinstance(values, (list, tuple))
            or len(values) > MAX_PARSEABLE_INPUT_LENGTH
            or any(type(value) is not int or not -(1 << 63) <= value < (1 << 63)
                   for value in values)):
        return None
    if input_length is not None and (
            type(input_length) is not int or input_length != len(values)):
        return None
    if len(values) < 2:
        return None
    capacity, count = values[:2]
    if not 1 <= capacity <= MAX_CAPACITY or not 0 <= count <= MAX_REQUESTS:
        return None
    if len(values) != 2 + count:
        return None
    requests = tuple(values[2:])
    if any(not 0 <= page < PAGE_COUNT for page in requests):
        return None
    return capacity, requests


def _simulate(capacity: int, requests: tuple[int, ...]) -> tuple[int, int]:
    count = len(requests)
    next_after = [[count] * PAGE_COUNT for _ in requests]
    next_position = [count] * PAGE_COUNT
    for time in range(count - 1, -1, -1):
        next_after[time] = next_position.copy()
        next_position[requests[time]] = time

    resident = [False] * PAGE_COUNT
    resident_count = 0
    misses = 0
    eviction_checksum = 0
    for time, requested in enumerate(requests):
        if resident[requested]:
            continue
        misses += 1
        if resident_count == capacity:
            victim = -1
            farthest = -1
            for page, is_resident in enumerate(resident):
                if not is_resident:
                    continue
                following = next_after[time][page]
                if following > farthest:
                    victim, farthest = page, following
            resident[victim] = False
            resident_count -= 1
            eviction_checksum += (time + 1) * (victim + 1)
        resident[requested] = True
        resident_count += 1
    return misses, eviction_checksum


def expected_result(values: Sequence[int] | None, input_is_null: bool = False,
                    input_length: int | None = None) -> int:
    parsed = _parse(values, input_is_null, input_length)
    if parsed is None:
        return -1
    capacity, requests = parsed
    misses, evictions = _simulate(capacity, requests)
    return misses * CHECKSUM_RADIX + evictions
