"""Oracle for the bounded TheAlgorithms JavaScript KeyPriorityQueue benchmark."""
from __future__ import annotations

from collections.abc import Sequence
import struct

MAX_OPERATIONS = 32
MAX_INPUT_LENGTH = 1 + 3 * MAX_OPERATIONS + 1
MAX_OUTPUT_BYTES = 8 * MAX_OPERATIONS
INVALID_RESULT = -1
INSUFFICIENT_OUTPUT_CAPACITY = -2
KEY_MIN = -(10**9)
KEY_MAX = 10**9
PRIORITY_MIN = -(10**9)
PRIORITY_MAX = 10**9


def expected_output(values: Sequence[int] | None, capacity: int | None = None,
                    output_is_null: bool = False, input_is_null: bool = False,
                    input_length: int | None = None) -> tuple[int, bytes]:
    if type(output_is_null) is not bool or type(input_is_null) is not bool:
        return INVALID_RESULT, b""
    if input_is_null or values is None or not isinstance(values, (list, tuple)):
        return INVALID_RESULT, b""
    if input_length is not None and (type(input_length) is not int or input_length != len(values)):
        return INVALID_RESULT, b""
    if not values or len(values) > MAX_INPUT_LENGTH:
        return INVALID_RESULT, b""
    if any(type(v) is not int or not -(1 << 63) <= v < (1 << 63) for v in values):
        return INVALID_RESULT, b""

    count = values[0]
    if not 0 <= count <= MAX_OPERATIONS:
        return INVALID_RESULT, b""
    heap: list[int] = []
    priorities: dict[int, int] = {}
    answers: list[int] = []
    pos = 1

    def shift_up(index: int) -> None:
        while index > 0:
            parent = (index - 1) // 2
            if priorities[heap[parent]] <= priorities[heap[index]]:
                break
            heap[parent], heap[index] = heap[index], heap[parent]
            index = parent

    def shift_down(index: int) -> None:
        while True:
            left = 2 * index + 1
            right = left + 1
            if left >= len(heap):
                break
            current_priority = priorities[heap[index]]
            left_priority = priorities[heap[left]]
            right_priority = priorities[heap[right]] if right < len(heap) else float("inf")
            if left_priority < current_priority and left_priority < right_priority:
                child = left
            elif right < len(heap) and right_priority < current_priority:
                child = right
            else:
                break
            heap[index], heap[child] = heap[child], heap[index]
            index = child

    for _ in range(count):
        if pos >= len(values):
            return INVALID_RESULT, b""
        operation = values[pos]
        if operation in (0, 1):
            if pos + 2 >= len(values):
                return INVALID_RESULT, b""
            key, priority = values[pos + 1], values[pos + 2]
            if not KEY_MIN <= key <= KEY_MAX or not PRIORITY_MIN <= priority <= PRIORITY_MAX:
                return INVALID_RESULT, b""
            pos += 3
            if operation == 0:
                if key in priorities:
                    return INVALID_RESULT, b""
                heap.append(key)
                priorities[key] = priority
                shift_up(len(heap) - 1)
            elif key not in priorities:
                heap.append(key)
                priorities[key] = priority
                shift_up(len(heap) - 1)
            else:
                priorities[key] = priority
                index = heap.index(key)
                if index > 0 and priorities[heap[(index - 1) // 2]] > priority:
                    shift_up(index)
                else:
                    left, right = 2 * index + 1, 2 * index + 2
                    if ((left < len(heap) and priorities[heap[left]] < priority) or
                            (right < len(heap) and priorities[heap[right]] < priority)):
                        shift_down(index)
        elif operation == 2:
            pos += 1
            if not heap:
                return INVALID_RESULT, b""
            heap[0], heap[-1] = heap[-1], heap[0]
            key = heap.pop()
            del priorities[key]
            if heap:
                shift_down(0)
            answers.append(key)
        elif operation == 3:
            if pos + 1 >= len(values):
                return INVALID_RESULT, b""
            key = values[pos + 1]
            if not KEY_MIN <= key <= KEY_MAX:
                return INVALID_RESULT, b""
            pos += 2
            answers.append(int(key in priorities))
        elif operation == 4:
            pos += 1
            answers.append(int(not heap))
        else:
            return INVALID_RESULT, b""
    if pos != len(values):
        return INVALID_RESULT, b""
    if capacity is not None and (type(capacity) is not int or capacity < 0):
        return INVALID_RESULT, b""
    if output_is_null or (capacity is not None and capacity < 8 * len(answers)):
        return INSUFFICIENT_OUTPUT_CAPACITY, b""
    return 8 * len(answers), b"".join(struct.pack("<q", answer) for answer in answers)
