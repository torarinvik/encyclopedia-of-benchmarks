"""Oracle for the bounded Go Singly linked-list operation trace."""

from __future__ import annotations

from collections.abc import Sequence
import struct

MAX_INITIAL_NODES = 32
MAX_OPERATIONS = 64
MAX_LIST_NODES = MAX_INITIAL_NODES + MAX_OPERATIONS
MIN_VALUE = -1_000_000
MAX_VALUE = 1_000_000
MAX_VALID_INPUT_VALUES = 2 + MAX_INITIAL_NODES + 3 * MAX_OPERATIONS
MAX_PARSEABLE_INPUT_VALUES = MAX_VALID_INPUT_VALUES + 1
MAX_OUTPUT_VALUES = 1 + MAX_LIST_NODES + 1 + 2 * MAX_OPERATIONS
MAX_OUTPUT_BYTES = 8 * MAX_OUTPUT_VALUES
INVALID_RESULT = -1
INSUFFICIENT_CAPACITY_RESULT = -2
I64_MIN = -(1 << 63)
I64_MAX = (1 << 63) - 1


def _parse_input(values: Sequence[int] | None):
    if (
        not isinstance(values, (list, tuple))
        or not 2 <= len(values) <= MAX_PARSEABLE_INPUT_VALUES
        or any(type(value) is not int or not I64_MIN <= value <= I64_MAX for value in values)
    ):
        return None

    initial_count, operation_count = values[0], values[1]
    if not 0 <= initial_count <= MAX_INITIAL_NODES or not 0 <= operation_count <= MAX_OPERATIONS:
        return None
    cursor = 2
    if len(values) < cursor + initial_count:
        return None
    initial_values = list(values[cursor : cursor + initial_count])
    cursor += initial_count
    if any(not MIN_VALUE <= value <= MAX_VALUE for value in initial_values):
        return None

    operations: list[tuple[int, tuple[int, ...]]] = []
    for _ in range(operation_count):
        if cursor >= len(values):
            return None
        opcode = values[cursor]
        cursor += 1
        arity = {0: 1, 1: 1, 2: 0, 3: 0, 4: 1, 5: 0, 6: 2}.get(opcode)
        if arity is None or cursor + arity > len(values):
            return None
        arguments = tuple(values[cursor : cursor + arity])
        cursor += arity
        if opcode in (0, 1) and not MIN_VALUE <= arguments[0] <= MAX_VALUE:
            return None
        operations.append((opcode, arguments))

    if cursor != len(values):
        return None
    return initial_values, operations


def _run(values: Sequence[int] | None) -> tuple[list[int], list[int]] | None:
    parsed = _parse_input(values)
    if parsed is None:
        return None
    linked_values, operations = parsed
    operation_results: list[int] = []

    for opcode, arguments in operations:
        if opcode == 0:
            linked_values.insert(0, arguments[0])
            operation_results.extend((1, 0))
        elif opcode == 1:
            linked_values.append(arguments[0])
            operation_results.extend((1, 0))
        elif opcode == 2:
            if linked_values:
                value = linked_values.pop(0)
                operation_results.extend((1, value))
            else:
                operation_results.extend((0, 0))
        elif opcode == 3:
            if linked_values:
                value = linked_values.pop()
                operation_results.extend((1, value))
            else:
                operation_results.extend((0, 0))
        elif opcode == 4:
            position = arguments[0]
            if not linked_values:
                if position != 1:
                    return None
                operation_results.extend((0, 0))
            elif not 1 <= position <= len(linked_values) + 1:
                return None
            else:
                index = min(position - 1, len(linked_values) - 1)
                value = linked_values.pop(index)
                operation_results.extend((1, value))
        elif opcode == 5:
            linked_values.reverse()
            operation_results.extend((1, 0))
        else:
            left, right = arguments
            if not 1 <= left <= right <= len(linked_values):
                return None
            linked_values[left - 1 : right] = reversed(linked_values[left - 1 : right])
            operation_results.extend((1, 0))

    output_values = [len(linked_values), *linked_values, len(operations), *operation_results]
    return output_values, operations


def expected_output(
    values: Sequence[int] | None,
    capacity: int | None = None,
    input_is_null: bool = False,
    output_is_null: bool = False,
    input_length: int | None = None,
) -> tuple[int, bytes]:
    """Return status and packed final list plus per-operation results."""
    if input_is_null:
        return INVALID_RESULT, b""
    if input_length is not None and (
        type(input_length) is not int
        or not isinstance(values, (list, tuple))
        or input_length != len(values)
    ):
        return INVALID_RESULT, b""
    result = _run(values)
    if result is None:
        return INVALID_RESULT, b""
    output_values, _ = result
    output = struct.pack("<" + "q" * len(output_values), *output_values)
    if output_is_null or (capacity is not None and capacity < len(output)):
        return INSUFFICIENT_CAPACITY_RESULT, b""
    return len(output), output


def expected_result(
    values: Sequence[int] | None,
    capacity: int | None = None,
    input_is_null: bool = False,
    output_is_null: bool = False,
    input_length: int | None = None,
) -> int:
    """Return the ABI status/result for a list trace input view."""
    return expected_output(
        values, capacity, input_is_null, output_is_null, input_length
    )[0]
