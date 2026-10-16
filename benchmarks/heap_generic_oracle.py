"""Bounded operation oracle for the pinned Python generic max heap."""

from __future__ import annotations

MAX_OPERATIONS = 512
MAX_ITEMS = 128
MAX_ID = 4095
MIN_PRIORITY = -(1 << 31)
MAX_PRIORITY = (1 << 31) - 1
MAX_INPUT_LENGTH = 1 + 3 * MAX_OPERATIONS
MASK = (1 << 64) - 1
FNV_OFFSET = 0xCBF29CE484222325
FNV_PRIME = 0x100000001B3
INVALID_RESULT = -1


def _byte(h: int, value: int) -> int:
    return ((h ^ (value & 255)) * FNV_PRIME) & MASK


def _i32(h: int, value: int) -> int:
    bits = value & 0xFFFFFFFF
    for shift in (0, 8, 16, 24):
        h = _byte(h, bits >> shift)
    return h


def expected_result(values: list[int] | tuple[int, ...]) -> int:
    if (not isinstance(values, (list, tuple))
            or not 1 <= len(values) <= MAX_INPUT_LENGTH
            or any(type(value) is not int or not -(1 << 63) <= value < (1 << 63)
                   for value in values)):
        return INVALID_RESULT
    operation_count = values[0]
    if (not 0 <= operation_count <= MAX_OPERATIONS
            or len(values) != 1 + 3 * operation_count):
        return INVALID_RESULT

    heap: list[list[int]] = []  # [stable item ID, current priority]
    positions: dict[int, int] = {}
    used_ids: set[int] = set()
    h = FNV_OFFSET

    def swap(first: int, second: int) -> None:
        heap[first], heap[second] = heap[second], heap[first]
        positions[heap[first][0]] = first
        positions[heap[second][0]] = second

    def heapify_up(index: int) -> None:
        while index > 0:
            parent = (index - 1) // 2
            if heap[index][1] <= heap[parent][1]:
                break
            swap(index, parent)
            index = parent

    def heapify_down(index: int) -> None:
        while True:
            best = index
            left = 2 * index + 1
            right = left + 1
            if left < len(heap) and heap[left][1] > heap[best][1]:
                best = left
            if right < len(heap) and heap[right][1] > heap[best][1]:
                best = right
            if best == index:
                return
            swap(index, best)
            index = best

    def erase(item_id: int) -> None:
        index = positions.pop(item_id)
        last = len(heap) - 1
        if index != last:
            heap[index] = heap[last]
            positions[heap[index][0]] = index
        heap.pop()
        if index < len(heap):
            heapify_up(index)
            heapify_down(index)  # source repairs down from the original index

    for operation in range(operation_count):
        opcode, item_id, priority = values[1 + 3 * operation:4 + 3 * operation]
        returned: tuple[int, int] | None = None

        if opcode == 0:
            if (not 0 <= item_id <= MAX_ID
                    or not MIN_PRIORITY <= priority <= MAX_PRIORITY
                    or item_id in used_ids
                    or len(heap) >= MAX_ITEMS
                    or any(entry[1] == priority for entry in heap)):
                return INVALID_RESULT
            used_ids.add(item_id)
            positions[item_id] = len(heap)
            heap.append([item_id, priority])
            heapify_up(len(heap) - 1)
        elif opcode == 1 or opcode == 2:
            if item_id != 0 or priority != 0:
                return INVALID_RESULT
            if heap:
                returned = (heap[0][0], heap[0][1])
                if opcode == 2:
                    erase(returned[0])
        elif opcode == 3:
            if (not 0 <= item_id <= MAX_ID
                    or not MIN_PRIORITY <= priority <= MAX_PRIORITY
                    or item_id not in positions):
                return INVALID_RESULT
            index = positions[item_id]
            if any(i != index and entry[1] == priority for i, entry in enumerate(heap)):
                return INVALID_RESULT
            heap[index][1] = priority
            heapify_up(index)
            heapify_down(index)  # match the source's original-index call order
        elif opcode == 4:
            if (not 0 <= item_id <= MAX_ID or priority != 0
                    or item_id not in positions):
                return INVALID_RESULT
            erase(item_id)
        else:
            return INVALID_RESULT

        h = _byte(h, opcode)
        h = _byte(h, int(returned is not None))
        if returned is not None:
            h = _i32(h, returned[0])
            h = _i32(h, returned[1])

    return h if h < (1 << 63) else h - (1 << 64)
