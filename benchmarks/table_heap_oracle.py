"""Oracle for the bounded Lua table-backed priority heap trace."""

from __future__ import annotations

from collections.abc import Sequence
import struct

I32_MIN = -(1 << 31)
I32_MAX = (1 << 31) - 1
I64_MIN = -(1 << 63)
I64_MAX = (1 << 63) - 1
NIL_SENTINEL = I64_MIN
MAX_INITIAL_ITEMS = 64
MAX_OPERATIONS = 256
MAX_VALID_INPUT_LENGTH = 2 + 2 * MAX_INITIAL_ITEMS + 4 * MAX_OPERATIONS
MAX_PARSEABLE_INPUT_LENGTH = MAX_VALID_INPUT_LENGTH + 1
MAX_OUTPUT_BYTES = 8 * MAX_OPERATIONS
INVALID_RESULT = -1
OUTPUT_ERROR = -2


def _swap(heap: list[int], indices: dict[int, int], left: int, right: int) -> None:
    """Swap 1-based heap positions and keep the table-heap index map current."""
    left_id = heap[left - 1]
    right_id = heap[right - 1]
    heap[left - 1], heap[right - 1] = right_id, left_id
    indices[left_id] = right
    indices[right_id] = left


def _heapify_down(
    heap: list[int], priorities: dict[int, int], indices: dict[int, int] | None, index: int
) -> None:
    """Mirror heap.lua: start with the right child and retain strict ties."""
    left_child = index * 2
    if left_child > len(heap):
        return

    smallest_child = left_child + 1  # right child wins an equal-priority tie
    if (smallest_child > len(heap)
            or priorities[heap[left_child - 1]] < priorities[heap[smallest_child - 1]]):
        smallest_child = left_child

    if priorities[heap[smallest_child - 1]] < priorities[heap[index - 1]]:
        if indices is None:
            heap[index - 1], heap[smallest_child - 1] = (
                heap[smallest_child - 1], heap[index - 1]
            )
        else:
            _swap(heap, indices, index, smallest_child)
        _heapify_down(heap, priorities, indices, smallest_child)


def _heapify_up(
    heap: list[int], priorities: dict[int, int], indices: dict[int, int], index: int
) -> None:
    if index == 1:
        return
    parent = index // 2
    if priorities[heap[index - 1]] < priorities[heap[parent - 1]]:
        _swap(heap, indices, index, parent)
        _heapify_up(heap, priorities, indices, parent)


def _execute(values: Sequence[int]) -> list[int] | None:
    """Parse and replay one complete trace; None denotes an invalid trace."""
    if len(values) < 2 or len(values) > MAX_PARSEABLE_INPUT_LENGTH:
        return None
    if any(type(value) is not int or not I64_MIN <= value <= I64_MAX for value in values):
        return None

    initial_count = values[0]
    if not 0 <= initial_count <= MAX_INITIAL_ITEMS:
        return None
    operation_count_index = 1 + 2 * initial_count
    if len(values) <= operation_count_index:
        return None

    operation_count = values[operation_count_index]
    if not 0 <= operation_count <= MAX_OPERATIONS:
        return None
    expected_length = 2 + 2 * initial_count + 4 * operation_count
    if len(values) != expected_length or len(values) > MAX_VALID_INPUT_LENGTH:
        return None

    heap: list[int] = []
    priorities: dict[int, int] = {}
    cursor = 1
    for _ in range(initial_count):
        element, priority = values[cursor], values[cursor + 1]
        cursor += 2
        if (not I32_MIN <= element <= I32_MAX
                or not I32_MIN <= priority <= I32_MAX
                or element in priorities):
            return None
        heap.append(element)
        priorities[element] = priority

    # heap.new heapifies the array before table_heap.new creates its indices map.
    for parent in range(len(heap) // 2, 0, -1):
        _heapify_down(heap, priorities, None, parent)
    indices = {element: index for index, element in enumerate(heap, start=1)}

    answers: list[int] = []
    cursor = operation_count_index + 1
    for _ in range(operation_count):
        opcode, arg1, arg2, arg3 = values[cursor : cursor + 4]
        cursor += 4
        if opcode not in range(10):
            return None

        if opcode == 0:  # push(id, priority)
            element, priority = arg1, arg2
            if (not I32_MIN <= element <= I32_MAX
                    or not I32_MIN <= priority <= I32_MAX
                    or arg3 != 0 or element in indices
                    or len(heap) >= MAX_INITIAL_ITEMS):
                return None
            priorities[element] = priority
            heap.append(element)
            indices[element] = len(heap)
            _heapify_up(heap, priorities, indices, len(heap))
            answers.append(NIL_SENTINEL)
        elif opcode == 1:  # top()
            if arg1 != 0 or arg2 != 0 or arg3 != 0:
                return None
            answers.append(heap[0] if heap else NIL_SENTINEL)
        elif opcode == 2:  # pop()
            if arg1 != 0 or arg2 != 0 or arg3 != 0 or not heap:
                return None
            _swap(heap, indices, 1, len(heap))
            element = heap.pop()
            del indices[element]
            if heap:
                _heapify_down(heap, priorities, indices, 1)
            del priorities[element]
            answers.append(element)
        elif opcode == 3:  # size()
            if arg1 != 0 or arg2 != 0 or arg3 != 0:
                return None
            answers.append(len(heap))
        elif opcode == 4:  # empty()
            if arg1 != 0 or arg2 != 0 or arg3 != 0:
                return None
            answers.append(1 if not heap else 0)
        elif opcode == 5:  # find_index(id)
            if (not I32_MIN <= arg1 <= I32_MAX or arg2 != 0 or arg3 != 0):
                return None
            answers.append(indices.get(arg1, NIL_SENTINEL))
        elif opcode == 6:  # decrease(id, new_priority)
            element, new_priority = arg1, arg2
            if (not I32_MIN <= element <= I32_MAX
                    or not I32_MIN <= new_priority <= I32_MAX
                    or arg3 != 0 or element not in indices
                    or new_priority > priorities[element]):
                return None
            priorities[element] = new_priority
            _heapify_up(heap, priorities, indices, indices[element])
            answers.append(NIL_SENTINEL)
        elif opcode == 7:  # increase(id, new_priority)
            element, new_priority = arg1, arg2
            if (not I32_MIN <= element <= I32_MAX
                    or not I32_MIN <= new_priority <= I32_MAX
                    or arg3 != 0 or element not in indices
                    or new_priority < priorities[element]):
                return None
            priorities[element] = new_priority
            _heapify_down(heap, priorities, indices, indices[element])
            answers.append(NIL_SENTINEL)
        elif opcode == 8:  # replace(old_id, new_id, new_priority)
            old_element, new_element, new_priority = arg1, arg2, arg3
            if (not I32_MIN <= old_element <= I32_MAX
                    or not I32_MIN <= new_element <= I32_MAX
                    or not I32_MIN <= new_priority <= I32_MAX
                    or old_element not in indices):
                return None
            index = indices[old_element]
            if new_element in indices:
                if new_element != old_element or new_priority != priorities[old_element]:
                    return None
                # table_heap.replace returns immediately when replacing an item
                # with itself, so only the unchanged-priority case is admitted.
            else:
                old_priority = priorities[old_element]
                priorities[new_element] = new_priority
                heap[index - 1] = new_element
                del indices[old_element]
                indices[new_element] = index
                if new_priority < old_priority:
                    _heapify_up(heap, priorities, indices, index)
                else:
                    _heapify_down(heap, priorities, indices, index)
                del priorities[old_element]
            answers.append(NIL_SENTINEL)
        else:  # opcode == 9: remove(id)
            element = arg1
            if (not I32_MIN <= element <= I32_MAX
                    or arg2 != 0 or arg3 != 0 or element not in indices):
                return None
            index = indices[element]
            del indices[element]
            if index == len(heap):
                heap.pop()
            else:
                last_element = heap[-1]
                heap.pop()
                heap[index - 1] = last_element
                indices[last_element] = index
                if priorities[last_element] < priorities[element]:
                    _heapify_up(heap, priorities, indices, index)
                else:
                    _heapify_down(heap, priorities, indices, index)
            del priorities[element]
            answers.append(NIL_SENTINEL)

    return answers


def expected_output(
    values: Sequence[int] | None,
    capacity: int | None = None,
    output_is_null: bool = False,
    input_is_null: bool = False,
    input_length: int | None = None,
) -> tuple[int, bytes]:
    """Return one little-endian i64 result per operation or an ABI error."""
    if type(output_is_null) is not bool or type(input_is_null) is not bool:
        return INVALID_RESULT, b""
    if input_is_null or values is None or not isinstance(values, (list, tuple)):
        return INVALID_RESULT, b""
    if input_length is not None and (
        type(input_length) is not int or input_length < 0 or input_length != len(values)
    ):
        return INVALID_RESULT, b""

    answers = _execute(values)
    if answers is None:
        return INVALID_RESULT, b""
    if capacity is not None and (type(capacity) is not int or capacity < 0):
        return INVALID_RESULT, b""

    output = b"".join(struct.pack("<q", answer) for answer in answers)
    if len(output) > MAX_OUTPUT_BYTES:
        return INVALID_RESULT, b""
    if output_is_null or (capacity is not None and capacity < len(output)):
        return OUTPUT_ERROR, b""
    return len(output), output
