"""Primary bounded oracle for supplied-choice randomized Marking paging."""

from __future__ import annotations

import struct
from collections.abc import Sequence

MAX_CACHE_SIZE = 8
MAX_REQUESTS = 32
MAX_PAGE_ID = 15
MAX_INPUT_LENGTH = 67
MAX_VALID_INPUT_LENGTH = 66
MAX_OUTPUT_BYTES = 536
MAX_WORKSPACE_BYTES = 8192


def _parse(values: Sequence[int] | None):
    if (not isinstance(values, (list, tuple)) or not 3 <= len(values) <= MAX_INPUT_LENGTH
            or any(type(value) is not int or not -(1 << 63) <= value < (1 << 63)
                   for value in values)):
        return None
    capacity, request_count = values[:2]
    if not 1 <= capacity <= MAX_CACHE_SIZE or not 0 <= request_count <= MAX_REQUESTS:
        return None
    choice_count_index = 2 + request_count
    if len(values) <= choice_count_index:
        return None
    choice_count = values[choice_count_index]
    if not 0 <= choice_count <= request_count or len(values) != choice_count_index + 1 + choice_count:
        return None
    requests = tuple(values[2:choice_count_index])
    choices = tuple(values[choice_count_index + 1:])
    if any(not 0 <= page <= MAX_PAGE_ID for page in requests) or any(choice < 0 for choice in choices):
        return None
    return capacity, requests, choices


def _simulate(capacity: int, requests: tuple[int, ...], choices: tuple[int, ...]) -> list[int] | None:
    resident = [False] * (MAX_PAGE_ID + 1)
    marked = [False] * (MAX_PAGE_ID + 1)
    hit_flags: list[int] = []
    victim_ids: list[int] = []
    choice_cursor = 0
    misses = 0
    resident_count = 0

    for page in requests:
        if resident[page]:
            hit_flags.append(1)
            marked[page] = True
            victim_ids.append(-1)
            continue

        misses += 1
        hit_flags.append(0)
        victim = -1
        if resident_count == capacity:
            eligible = [candidate for candidate in range(MAX_PAGE_ID + 1)
                        if resident[candidate] and not marked[candidate]]
            if not eligible:
                for candidate in range(MAX_PAGE_ID + 1):
                    if resident[candidate]:
                        marked[candidate] = False
                        eligible.append(candidate)
            if choice_cursor >= len(choices):
                return None
            choice = choices[choice_cursor]
            choice_cursor += 1
            if choice >= len(eligible):
                return None
            victim = eligible[choice]
            resident[victim] = False
            marked[victim] = False
            resident_count -= 1
        resident[page] = True
        marked[page] = True
        resident_count += 1
        victim_ids.append(victim)

    if choice_cursor != len(choices):
        return None
    resident_mask = sum(1 << page for page, present in enumerate(resident) if present)
    marked_mask = sum(1 << page for page, present in enumerate(marked) if present)
    return [misses, resident_mask, marked_mask, *hit_flags, *victim_ids]


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
    parsed = _parse(values)
    if parsed is None:
        return -1, b""
    cache_size, requests, choices = parsed
    words = _simulate(cache_size, requests, choices)
    if words is None:
        return -1, b""
    payload = struct.pack("<" + "q" * len(words), *words)
    if output_is_null or capacity is not None and capacity < len(payload):
        return -2, b""
    return len(payload), payload
