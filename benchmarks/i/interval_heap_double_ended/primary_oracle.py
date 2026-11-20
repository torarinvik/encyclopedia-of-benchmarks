"""Clean-room paired-endpoint interval-heap oracle for bounded DEPQ traces."""

from __future__ import annotations

import struct
from collections.abc import Sequence

MAX_INITIAL = 64
MAX_OPERATIONS = 128
MAX_KEYS = MAX_INITIAL + MAX_OPERATIONS
MAX_INPUT_LENGTH = MAX_INITIAL + 2 + 2 * MAX_OPERATIONS
MAX_OUTPUT_BYTES = 1552
WORKSPACE_BYTES = 8192
I32_MIN = -(1 << 31)
I32_MAX = (1 << 31) - 1


class IntervalHeap:
    """One flat array stores consecutive low/high endpoint pairs."""

    def __init__(self) -> None:
        self.keys: list[int] = []

    def __len__(self) -> int:
        return len(self.keys)

    def _high(self, node: int) -> int:
        return 2 * node + 1 if 2 * node + 1 < len(self.keys) else 2 * node

    def _sift_up_low(self, node: int) -> None:
        while node > 0:
            parent = (node - 1) // 2
            low = 2 * node
            parent_low = 2 * parent
            if self.keys[low] >= self.keys[parent_low]:
                return
            self.keys[low], self.keys[parent_low] = self.keys[parent_low], self.keys[low]
            node = parent

    def _sift_up_high(self, node: int) -> None:
        while node > 0:
            parent = (node - 1) // 2
            high = self._high(node)
            parent_high = self._high(parent)
            if self.keys[high] <= self.keys[parent_high]:
                return
            self.keys[high], self.keys[parent_high] = self.keys[parent_high], self.keys[high]
            node = parent

    def insert(self, value: int) -> None:
        self.keys.append(value)
        key_index = len(self.keys) - 1
        node = key_index // 2
        if key_index % 2 == 1 and self.keys[key_index] < self.keys[key_index - 1]:
            self.keys[key_index], self.keys[key_index - 1] = self.keys[key_index - 1], self.keys[key_index]
        self._sift_up_low(node)
        self._sift_up_high(node)

    def minimum(self) -> int:
        return self.keys[0]

    def maximum(self) -> int:
        return self.keys[self._high(0)]

    def extract_minimum(self) -> int:
        removed = self.keys[0]
        last = self.keys.pop()
        if not self.keys:
            return removed
        self.keys[0] = last
        node = 0
        while True:
            left = 2 * node + 1
            if 2 * left >= len(self.keys):
                return removed
            right = left + 1
            child = left
            if 2 * right < len(self.keys) and self.keys[2 * right] < self.keys[2 * left]:
                child = right
            child_low = 2 * child
            node_low = 2 * node
            if self.keys[child_low] >= self.keys[node_low]:
                return removed
            self.keys[node_low], self.keys[child_low] = self.keys[child_low], self.keys[node_low]
            child_high = self._high(child)
            if self.keys[child_high] < self.keys[child_low]:
                self.keys[child_high], self.keys[child_low] = self.keys[child_low], self.keys[child_high]
            node = child

    def extract_maximum(self) -> int:
        if len(self.keys) <= 2:
            return self.keys.pop()
        removed = self.keys[1]
        self.keys[1] = self.keys.pop()
        node = 0
        while True:
            left = 2 * node + 1
            if 2 * left >= len(self.keys):
                return removed
            right = left + 1
            child = left
            if 2 * right < len(self.keys) and self.keys[self._high(left)] < self.keys[self._high(right)]:
                child = right
            node_high = self._high(node)
            child_high = self._high(child)
            if self.keys[node_high] >= self.keys[child_high]:
                return removed
            self.keys[node_high], self.keys[child_high] = self.keys[child_high], self.keys[node_high]
            if self.keys[child_high] < self.keys[2 * child]:
                self.keys[child_high], self.keys[2 * child] = self.keys[2 * child], self.keys[child_high]
            node = child


def _parse(values: Sequence[int] | None):
    if not isinstance(values, (list, tuple)) or not 2 <= len(values) <= MAX_INPUT_LENGTH:
        return None
    if any(type(value) is not int or not -(1 << 63) <= value < (1 << 63) for value in values):
        return None
    initial_count = values[0]
    if not 0 <= initial_count <= MAX_INITIAL or len(values) < initial_count + 2:
        return None
    operation_count = values[initial_count + 1]
    if not 0 <= operation_count <= MAX_OPERATIONS:
        return None
    if len(values) != initial_count + 2 + 2 * operation_count:
        return None
    initial = values[1:initial_count + 1]
    if any(value < I32_MIN or value > I32_MAX for value in initial):
        return None
    operations = []
    for offset in range(operation_count):
        opcode, argument = values[initial_count + 2 + 2 * offset:initial_count + 4 + 2 * offset]
        if not 0 <= opcode <= 5:
            return None
        if opcode == 0:
            if not I32_MIN <= argument <= I32_MAX:
                return None
        elif argument != 0:
            return None
        operations.append((opcode, argument))
    return initial, operations


def expected_output(values: Sequence[int] | None, capacity: int | None = None,
                    output_is_null: bool = False, input_is_null: bool = False,
                    input_length: int | None = None) -> tuple[int, bytes]:
    if type(output_is_null) is not bool or type(input_is_null) is not bool:
        return -1, b""
    if capacity is not None and (type(capacity) is not int or capacity < 0):
        return -1, b""
    if input_length is not None and (type(input_length) is not int or not 0 <= input_length <= MAX_INPUT_LENGTH):
        return -1, b""
    if input_is_null or values is None or not isinstance(values, (list, tuple)):
        return -1, b""
    if input_length is not None and input_length != len(values):
        return -1, b""
    parsed = _parse(values)
    if parsed is None:
        return -1, b""

    initial, operations = parsed
    heap = IntervalHeap()
    for value in initial:
        heap.insert(value)
    events: list[int] = []
    for opcode, argument in operations:
        if opcode == 0:
            heap.insert(argument)
        elif opcode == 1:
            if not heap:
                return -1, b""
            events.append(heap.minimum())
        elif opcode == 2:
            if not heap:
                return -1, b""
            events.append(heap.maximum())
        elif opcode == 3:
            if not heap:
                return -1, b""
            events.append(heap.extract_minimum())
        elif opcode == 4:
            if not heap:
                return -1, b""
            events.append(heap.extract_maximum())
        else:
            events.append(len(heap))

    final_values = sorted(heap.keys)
    words = (len(events), *events, len(final_values), *final_values)
    payload = b"".join(struct.pack("<q", word) for word in words)
    if output_is_null or capacity is not None and capacity < len(payload):
        return -2, b""
    return len(payload), payload
