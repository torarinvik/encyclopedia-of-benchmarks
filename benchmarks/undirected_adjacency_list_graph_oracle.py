"""Oracle for the bounded indexed undirected weighted adjacency-list graph."""

from __future__ import annotations

import struct
from collections.abc import Sequence

MAX_NODES = 8
MAX_OPERATIONS = 24
MAX_VALID_INPUT_LENGTH = 1 + 4 * MAX_OPERATIONS
MAX_PARSEABLE_INPUT_LENGTH = MAX_VALID_INPUT_LENGTH + 1
MAX_OUTPUT_WORDS = 144
MAX_OUTPUT_BYTES = MAX_OUTPUT_WORDS * 8
INT32_MIN = -(1 << 31)
INT32_MAX = (1 << 31) - 1

OP_ADD_NODE = 0
OP_ADD_EDGE = 1
OP_NEIGHBORS = 2
OP_EDGE_WEIGHT = 3
OP_SIZE = 4

INVALID_RESULT = -1
OUTPUT_ERROR = -2


def _parse(values: Sequence[int] | None) -> list[tuple[int, int, int, int]] | None:
    if (not isinstance(values, (list, tuple))
            or not 1 <= len(values) <= MAX_PARSEABLE_INPUT_LENGTH
            or any(type(value) is not int or not -(1 << 63) <= value < (1 << 63)
                   for value in values)):
        return None
    operation_count = values[0]
    if not 0 <= operation_count <= MAX_OPERATIONS:
        return None
    if len(values) != 1 + 4 * operation_count:
        return None

    operations: list[tuple[int, int, int, int]] = []
    for offset in range(1, len(values), 4):
        operation, first, second, third = values[offset:offset + 4]
        if operation not in (OP_ADD_NODE, OP_ADD_EDGE, OP_NEIGHBORS, OP_EDGE_WEIGHT, OP_SIZE):
            return None
        if operation in (OP_ADD_NODE, OP_SIZE):
            if (first, second, third) != (0, 0, 0):
                return None
        elif operation == OP_ADD_EDGE:
            if not all(INT32_MIN <= value <= INT32_MAX
                       for value in (first, second, third)):
                return None
        elif operation == OP_NEIGHBORS:
            if not INT32_MIN <= first <= INT32_MAX or second != 0 or third != 0:
                return None
        elif operation == OP_EDGE_WEIGHT:
            if (not INT32_MIN <= first <= INT32_MAX
                    or not INT32_MIN <= second <= INT32_MAX or third != 0):
                return None
        operations.append((operation, first, second, third))
    return operations


def _simulate(values: Sequence[int] | None) -> list[int] | None:
    operations = _parse(values)
    if operations is None:
        return None

    adjacency: list[dict[int, int]] = [dict() for _ in range(MAX_NODES)]
    node_count = 0
    words: list[int] = []

    def record(operation: int, payload: list[int]) -> None:
        words.extend((operation, len(payload), *payload))

    for operation, first, second, third in operations:
        if operation == OP_ADD_NODE:
            if node_count >= MAX_NODES:
                return None
            new_index = node_count
            node_count += 1
            record(operation, [new_index])
        elif operation == OP_ADD_EDGE:
            added = False
            if (0 <= first < node_count and 0 <= second < node_count
                    and second not in adjacency[first]):
                adjacency[first][second] = third
                adjacency[second][first] = third
                added = True
            record(operation, [int(added)])
        elif operation == OP_NEIGHBORS:
            if not 0 <= first < node_count:
                return None
            neighbors = sorted(adjacency[first])
            record(operation, [len(neighbors), *neighbors])
        elif operation == OP_EDGE_WEIGHT:
            if not 0 <= first < node_count:
                return None
            if second in adjacency[first]:
                record(operation, [1, adjacency[first][second]])
            else:
                record(operation, [0, 0])
        else:
            record(operation, [node_count])

    if len(words) > MAX_OUTPUT_WORDS:
        return None
    return words


def expected_output(
    values: Sequence[int] | None,
    output_capacity: int | None = MAX_OUTPUT_BYTES,
    output_is_null: bool = False,
    input_is_null: bool = False,
    input_length: int | None = None,
) -> tuple[int, bytes]:
    """Return operation responses or the documented ABI error."""
    if type(output_is_null) is not bool or type(input_is_null) is not bool:
        return INVALID_RESULT, b""
    if output_capacity is not None and (
        type(output_capacity) is not int or output_capacity < 0
    ):
        return INVALID_RESULT, b""
    if input_length is not None and (
        type(input_length) is not int or input_length < 0
    ):
        return INVALID_RESULT, b""
    if input_is_null or values is None or not isinstance(values, (list, tuple)):
        return INVALID_RESULT, b""
    if input_length is not None and input_length != len(values):
        return INVALID_RESULT, b""

    words = _simulate(values)
    if words is None:
        return INVALID_RESULT, b""
    output = struct.pack("<" + "q" * len(words), *words)
    if output_is_null or (
        output_capacity is not None and output_capacity < len(output)
    ):
        return OUTPUT_ERROR, b""
    return len(output), output
