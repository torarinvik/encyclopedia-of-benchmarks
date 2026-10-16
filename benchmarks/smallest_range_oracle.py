"""Reference oracle for the bounded smallest-range workload."""

from __future__ import annotations

import heapq

MAX_LISTS = 16
MAX_LIST_LENGTH = 16
MAX_VALUES = 256
VALUE_MIN = -1_000_000_000
VALUE_MAX = 1_000_000_000
BASE = 1_000_000_000
RADIX = 2_000_000_001


def decode(packed: list[int]) -> list[list[int]] | None:
    """Decode and validate `[list_count, length, values..., ...]`."""
    if not isinstance(packed, list) or any(type(value) is not int for value in packed):
        return None
    if len(packed) < 2 or len(packed) > 1 + MAX_LISTS * (MAX_LIST_LENGTH + 1):
        return None
    count = packed[0]
    if not 1 <= count <= MAX_LISTS:
        return None
    offset = 1
    total = 0
    lists: list[list[int]] = []
    for _ in range(count):
        if offset >= len(packed) or not 1 <= packed[offset] <= MAX_LIST_LENGTH:
            return None
        length = packed[offset]
        offset += 1
        total += length
        if total > MAX_VALUES or offset + length > len(packed):
            return None
        values = packed[offset:offset + length]
        offset += length
        if any(not VALUE_MIN <= value <= VALUE_MAX for value in values):
            return None
        if any(values[i] > values[i + 1] for i in range(length - 1)):
            return None
        lists.append(values)
    return lists if offset == len(packed) else None


def oracle(packed: list[int]) -> int:
    """Return the source traversal's encoded interval, or -1 for invalid input."""
    lists = decode(packed)
    if lists is None:
        return -1
    heap: list[tuple[int, int, int]] = []
    current_max = VALUE_MIN - 1
    for list_index, values in enumerate(lists):
        heapq.heappush(heap, (values[0], list_index, 0))
        current_max = max(current_max, values[0])

    best_lo = best_hi = 0
    best_width = 2 * BASE + 1
    while True:
        lo, list_index, value_index = heapq.heappop(heap)
        width = current_max - lo
        if width < best_width:
            best_width = width
            best_lo, best_hi = lo, current_max
        value_index += 1
        if value_index == len(lists[list_index]):
            break
        value = lists[list_index][value_index]
        current_max = max(current_max, value)
        heapq.heappush(heap, (value, list_index, value_index))
    return (best_lo + BASE) * RADIX + (best_hi + BASE)
