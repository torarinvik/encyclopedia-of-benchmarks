"""Direct-suffix-scan verifier for offline optimal page replacement."""
from __future__ import annotations

from collections.abc import Sequence

from .primary_oracle import CHECKSUM_RADIX, MAX_CAPACITY, MAX_PARSEABLE_INPUT_LENGTH, MAX_REQUESTS, PAGE_COUNT


def _parse(values: Sequence[int] | None, input_is_null: bool,
           input_length: int | None) -> tuple[int, tuple[int, ...]] | None:
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
    if len(values) != count + 2:
        return None
    requests = tuple(values[2:])
    if any(not 0 <= page < PAGE_COUNT for page in requests):
        return None
    return capacity, requests


def expected_result(values: Sequence[int] | None, input_is_null: bool = False,
                    input_length: int | None = None) -> int:
    parsed = _parse(values, input_is_null, input_length)
    if parsed is None:
        return -1
    capacity, requests = parsed
    resident: set[int] = set()
    misses = 0
    checksum = 0
    for time, requested in enumerate(requests):
        if requested in resident:
            continue
        misses += 1
        if len(resident) == capacity:
            victim = min(
                resident,
                key=lambda page: (
                    -next((future for future in range(time + 1, len(requests))
                           if requests[future] == page), len(requests)),
                    page,
                ),
            )
            resident.remove(victim)
            checksum += (time + 1) * (victim + 1)
        resident.add(requested)
    return misses * CHECKSUM_RADIX + checksum
