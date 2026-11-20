"""Shortest-list-first inverted-list intersection with monotone lower bounds."""
from __future__ import annotations

import struct
from collections.abc import Sequence

MIN_LISTS = 2
MAX_LISTS = 8
MAX_LIST_LENGTH = 32
MAX_VALID_INPUT_LENGTH = 1 + MAX_LISTS * (MAX_LIST_LENGTH + 1)
MAX_PARSEABLE_INPUT_LENGTH = MAX_VALID_INPUT_LENGTH + 1
MAX_OUTPUT_BYTES = MAX_LIST_LENGTH * 4
WORKSPACE_BYTES = 4096
I64_MIN = -(1 << 63)
I64_MAX = (1 << 63) - 1
I32_MIN = -(1 << 31)
I32_MAX = (1 << 31) - 1


def _parse(values: Sequence[int]):
    if not MIN_LISTS + 1 <= len(values) <= MAX_PARSEABLE_INPUT_LENGTH:
        return None
    if any(type(value) is not int or not I64_MIN <= value <= I64_MAX for value in values):
        return None
    count = values[0]
    if not MIN_LISTS <= count <= MAX_LISTS:
        return None
    at = 1
    starts: list[int] = []
    sizes: list[int] = []
    for _ in range(count):
        if at >= len(values):
            return None
        size = values[at]
        at += 1
        if not 0 <= size <= MAX_LIST_LENGTH or size > len(values) - at:
            return None
        items = values[at:at + size]
        if (any(item < I32_MIN or item > I32_MAX for item in items)
                or any(items[index - 1] >= items[index] for index in range(1, size))):
            return None
        starts.append(at)
        sizes.append(size)
        at += size
    if at != len(values):
        return None
    return starts, sizes


def _shortest_list_first(values: Sequence[int], starts: Sequence[int],
                         sizes: Sequence[int]) -> list[int]:
    # Stable ordering uses original list ID as the secondary key.
    order = sorted(range(len(sizes)), key=lambda list_id: (sizes[list_id], list_id))
    shortest = order[0]
    candidates = [values[starts[shortest] + i] for i in range(sizes[shortest])]
    for list_id in order[1:]:
        start = starts[list_id]
        end = start + sizes[list_id]
        cursor = start
        kept: list[int] = []
        for candidate in candidates:
            low, high = cursor, end
            while low < high:
                middle = (low + high) // 2
                if values[middle] < candidate:
                    low = middle + 1
                else:
                    high = middle
            if low < end and values[low] == candidate:
                kept.append(candidate)
                cursor = low + 1
            else:
                cursor = low
        candidates = kept
        if not candidates:
            break
    return candidates


def expected_output(values: Sequence[int] | None, capacity: int | None = None,
                    output_is_null: bool = False, input_is_null: bool = False,
                    input_length: int | None = None) -> tuple[int, bytes]:
    if (type(output_is_null) is not bool or type(input_is_null) is not bool
            or capacity is not None and (type(capacity) is not int or capacity < 0)
            or input_length is not None and (type(input_length) is not int or input_length < 0)
            or input_is_null and values not in (None, [], ())
            or not input_is_null and values is not None and not isinstance(values, (list, tuple))
            or not input_is_null and values is not None and input_length is not None
            and input_length != len(values)):
        return -1, b""
    if input_is_null or values is None or not isinstance(values, (list, tuple)):
        return -1, b""
    parsed = _parse(values)
    if parsed is None:
        return -1, b""
    starts, sizes = parsed
    required = min(sizes) * 4
    if output_is_null and required > 0 or capacity is not None and capacity < required:
        return -2, b""
    result = _shortest_list_first(values, starts, sizes)
    payload = b"".join(struct.pack("<i", value) for value in result)
    return len(result), payload


def expected_result(values: Sequence[int] | None) -> int:
    return expected_output(values)[0]
