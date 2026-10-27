"""Independent resident-list verifier for supplied-choice Marking paging."""

from __future__ import annotations

import struct
from collections.abc import Sequence

MAX_CACHE_SIZE = 8
MAX_REQUESTS = 32
MAX_PAGE_ID = 15
MAX_INPUT_LENGTH = 67


def _decode(values: Sequence[int] | None):
    if (not isinstance(values, (list, tuple)) or not 3 <= len(values) <= MAX_INPUT_LENGTH
            or any(type(value) is not int or value < -(1 << 63) or value >= (1 << 63)
                   for value in values)):
        return None
    cache_size, count = values[0], values[1]
    if not 1 <= cache_size <= MAX_CACHE_SIZE or not 0 <= count <= MAX_REQUESTS:
        return None
    cursor = 2 + count
    if cursor >= len(values):
        return None
    draw_count = values[cursor]
    if not 0 <= draw_count <= count or len(values) != cursor + 1 + draw_count:
        return None
    requests = tuple(values[2:cursor])
    draws = tuple(values[cursor + 1:])
    if any(page < 0 or page > MAX_PAGE_ID for page in requests) or any(draw < 0 for draw in draws):
        return None
    return cache_size, requests, draws


def _verify(cache_size: int, requests: tuple[int, ...], draws: tuple[int, ...]) -> list[int] | None:
    # Keep residents as an explicit list, independent of the primary oracle's
    # page-indexed presence table. Marks encode the current Marking phase.
    residents: list[int] = []
    marked: set[int] = set()
    hits: list[int] = []
    evictions: list[int] = []
    draw_at = 0
    misses = 0

    for page in requests:
        if page in residents:
            hits.append(1)
            marked.add(page)
            evictions.append(-1)
            continue

        misses += 1
        hits.append(0)
        removed = -1
        if len(residents) == cache_size:
            eligible = sorted(resident for resident in residents if resident not in marked)
            if not eligible:
                marked.clear()
                eligible = sorted(residents)
            if draw_at == len(draws) or draws[draw_at] >= len(eligible):
                return None
            removed = eligible[draws[draw_at]]
            draw_at += 1
            residents.remove(removed)
            marked.discard(removed)
        residents.append(page)
        marked.add(page)
        evictions.append(removed)

    if draw_at != len(draws):
        return None
    resident_mask = sum(1 << resident for resident in residents)
    marked_mask = sum(1 << resident for resident in residents if resident in marked)
    return [misses, resident_mask, marked_mask, *hits, *evictions]


def expected_output(values: Sequence[int] | None, capacity: int | None = None,
                    output_is_null: bool = False, input_is_null: bool = False,
                    input_length: int | None = None) -> tuple[int, bytes]:
    if (type(output_is_null) is not bool or type(input_is_null) is not bool
            or capacity is not None and (type(capacity) is not int or capacity < 0)
            or input_length is not None and (type(input_length) is not int
                                             or not 0 <= input_length <= MAX_INPUT_LENGTH)
            or input_is_null and values not in (None, [], ())
            or not input_is_null and values is not None and input_length is not None
            and input_length != len(values)):
        return -1, b""
    if input_is_null or values is None:
        return -1, b""
    decoded = _decode(values)
    if decoded is None:
        return -1, b""
    cache_size, requests, draws = decoded
    words = _verify(cache_size, requests, draws)
    if words is None:
        return -1, b""
    payload = struct.pack("<" + "q" * len(words), *words)
    if output_is_null or capacity is not None and capacity < len(payload):
        return -2, b""
    return len(payload), payload
