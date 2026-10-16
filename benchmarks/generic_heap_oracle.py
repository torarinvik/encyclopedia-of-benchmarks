"""Bounded operation oracle for Java GenericHeap with stable item identities."""
from __future__ import annotations

MAX_OPERATIONS = 256
MAX_INPUT_LENGTH = 1 + 3 * MAX_OPERATIONS
MAX_ITEMS = 128
INVALID_RESULT = -1
MASK = (1 << 64) - 1
OFFSET = 0xCBF29CE484222325
PRIME = 0x100000001B3

def _hash(h: int, value: int) -> int:
    bits = value & MASK
    for shift in range(0, 64, 8):
        h = ((h ^ ((bits >> shift) & 255)) * PRIME) & MASK
    return h

def expected_result(values: list[int] | tuple[int, ...]) -> int:
    if (not isinstance(values, (list, tuple)) or not 1 <= len(values) <= MAX_INPUT_LENGTH
            or any(type(v) is not int or not -(1 << 63) <= v < (1 << 63) for v in values)):
        return INVALID_RESULT
    count = values[0]
    if not 0 <= count <= MAX_OPERATIONS or len(values) != 1 + 3 * count:
        return INVALID_RESULT
    heap: list[list[int]] = []  # [stable item ID, mutable priority]
    positions: dict[int, int] = {}
    h = OFFSET

    def swap(i: int, j: int) -> None:
        heap[i], heap[j] = heap[j], heap[i]
        positions[heap[i][0]] = i
        positions[heap[j][0]] = j

    def up(i: int) -> None:
        while i > 0:
            parent = (i - 1) // 2
            if heap[i][1] <= heap[parent][1]:
                break
            swap(i, parent)
            i = parent

    def down(i: int) -> None:
        while True:
            largest = i
            left, right = 2 * i + 1, 2 * i + 2
            if left < len(heap) and heap[left][1] > heap[largest][1]:
                largest = left
            if right < len(heap) and heap[right][1] > heap[largest][1]:
                largest = right
            if largest == i:
                return
            swap(i, largest)
            i = largest

    for index in range(count):
        op, item, priority = values[1 + 3 * index:4 + 3 * index]
        if op == 0:
            if (not 0 <= item < 4096 or not -(1 << 31) <= priority < (1 << 31)
                    or item in positions or len(heap) >= MAX_ITEMS):
                return INVALID_RESULT
            positions[item] = len(heap)
            heap.append([item, priority])
            up(len(heap) - 1)
        elif op == 1:
            if item != 0 or priority != 0 or not heap:
                return INVALID_RESULT
            h = _hash(_hash(h, heap[0][0]), heap[0][1])
        elif op == 2:
            if item != 0 or priority != 0 or not heap:
                return INVALID_RESULT
            swap(0, len(heap) - 1)
            removed = heap.pop()
            del positions[removed[0]]
            if heap:
                down(0)
            h = _hash(_hash(h, removed[0]), removed[1])
        elif op == 3:
            if (not 0 <= item < 4096 or not -(1 << 31) <= priority < (1 << 31)
                    or item not in positions):
                return INVALID_RESULT
            pos = positions[item]
            heap[pos][1] = priority
            up(pos)  # pinned source only calls upHeapify after caller mutation
        elif op == 4:
            if item != 0 or priority != 0:
                return INVALID_RESULT
            h = _hash(h, len(heap))
        elif op == 5:
            if item != 0 or priority != 0:
                return INVALID_RESULT
            h = _hash(h, int(not heap))
        else:
            return INVALID_RESULT
    return h if h < (1 << 63) else h - (1 << 64)
