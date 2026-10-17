"""Oracle for the bounded C++ list_array operation trace."""

from __future__ import annotations

from collections.abc import Sequence
import struct

MAX_CAPACITY = 16
MAX_OPERATIONS = 64
MAX_VALID_INPUT_LENGTH = 2 + 2 * MAX_OPERATIONS
MAX_PARSEABLE_INPUT_LENGTH = MAX_VALID_INPUT_LENGTH
MAX_OUTPUT_BYTES = 520
I64_MIN = -(1 << 63)
I64_MAX = (1 << 63) - 1
INVALID_RESULT = -1
OUTPUT_ERROR = -2


def _binary_search(items: list[int], value: int, first: int, last: int) -> int:
    """Mirror the pinned recursive midpoint search, including duplicate hits."""
    if last < first:
        return -1
    middle = (first + last) // 2
    if items[middle] == value:
        return middle
    if value < items[middle]:
        return _binary_search(items, value, first, middle - 1)
    return _binary_search(items, value, middle + 1, last)


def _selection_sort(items: list[int]) -> None:
    """Mirror the source's in-place selection sort."""
    for i in range(len(items)):
        minimum = i
        for j in range(i + 1, len(items)):
            if items[j] < items[minimum]:
                minimum = j
        items[minimum], items[i] = items[i], items[minimum]


def expected_output(
    values: Sequence[int] | None,
    output_capacity: int | None = None,
    output_is_null: bool = False,
    input_is_null: bool = False,
    input_length: int | None = None,
) -> tuple[int, bytes]:
    """Return byte status and final list/search results for a valid trace."""
    if type(output_is_null) is not bool or type(input_is_null) is not bool:
        return INVALID_RESULT, b""
    if input_length is None:
        declared_length = len(values) if isinstance(values, (list, tuple)) else -1
    elif type(input_length) is int and input_length >= 0:
        declared_length = input_length
    else:
        return INVALID_RESULT, b""
    if (
        not isinstance(values, (list, tuple))
        or len(values) > MAX_PARSEABLE_INPUT_LENGTH
        or any(type(value) is not int or not I64_MIN <= value <= I64_MAX for value in values)
        or (input_is_null and len(values) != 0)
        or (not input_is_null and declared_length != len(values))
        or declared_length > MAX_PARSEABLE_INPUT_LENGTH
    ):
        return INVALID_RESULT, b""
    if input_is_null or declared_length < 2:
        return INVALID_RESULT, b""
    if output_capacity is not None and (
        type(output_capacity) is not int or output_capacity < 0
    ):
        return INVALID_RESULT, b""

    capacity, operation_count = values[0], values[1]
    if not 1 <= capacity <= MAX_CAPACITY or not 1 <= operation_count <= MAX_OPERATIONS:
        return INVALID_RESULT, b""
    if declared_length != 2 + 2 * operation_count:
        return INVALID_RESULT, b""

    operations: list[tuple[int, int]] = []
    sort_seen = False
    for i in range(operation_count):
        opcode, argument = values[2 + 2 * i : 4 + 2 * i]
        if opcode == 0:
            if sort_seen or not 0 <= argument <= I64_MAX:
                return INVALID_RESULT, b""
        elif opcode == 1:
            if sort_seen or argument != 0:
                return INVALID_RESULT, b""
            sort_seen = True
        elif opcode in (2, 3):
            if not sort_seen or not 0 <= argument <= I64_MAX:
                return INVALID_RESULT, b""
        else:
            return INVALID_RESULT, b""
        operations.append((opcode, argument))
    if not sort_seen:
        return INVALID_RESULT, b""

    items: list[int] = []
    results: list[int] = []
    for opcode, argument in operations:
        if opcode == 0:
            if len(items) == capacity:
                return INVALID_RESULT, b""
            items.append(argument)
        elif opcode == 1:
            _selection_sort(items)
        else:
            if not items or argument < items[0]:
                return INVALID_RESULT, b""
            if opcode == 3 and len(items) >= capacity:
                return INVALID_RESULT, b""
            position = _binary_search(items, argument, 0, len(items) - 1)
            results.append(position)
            if opcode == 3 and position >= 0:
                # The source also copies its spare data[top] slot, which is outside
                # this oracle's logical list. Only the live prefix remains active.
                for i in range(position, len(items) - 1):
                    items[i] = items[i + 1]
                items.pop()

    output_values = [len(results), *results, len(items), *items]
    output = b"".join(struct.pack("<q", value) for value in output_values)
    if len(output) > MAX_OUTPUT_BYTES:
        # This is an oracle invariant, not a normal input error.
        raise AssertionError("list_array output exceeds its published bound")
    if output_is_null or (output_capacity is not None and output_capacity < len(output)):
        return OUTPUT_ERROR, b""
    return len(output), output
