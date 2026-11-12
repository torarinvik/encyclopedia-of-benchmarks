"""Exhaustive-subset oracle for the bounded incremental XOR-basis workload."""

from __future__ import annotations

import struct

MAX_OPERATIONS = 64
MAX_INSERTIONS = 16
MAX_VALUE = (1 << 63) - 1
MAX_VALID_INPUT_LENGTH = 1 + 2 * MAX_OPERATIONS
MAX_PARSEABLE_INPUT_LENGTH = MAX_VALID_INPUT_LENGTH + 1
MAX_OUTPUT_BYTES = 8 * MAX_OPERATIONS


def _parse(values, input_is_null=False, input_length=None):
    if input_is_null or not isinstance(values, (list, tuple)):
        return None
    if input_length is None:
        input_length = len(values)
    if (type(input_length) is not int or input_length < 0
            or input_length > MAX_PARSEABLE_INPUT_LENGTH
            or input_length != len(values) or len(values) < 2):
        return None
    if any(type(word) is not int or not -(1 << 63) <= word < (1 << 63)
           for word in values):
        return None
    operation_count = values[0]
    if not 1 <= operation_count <= MAX_OPERATIONS:
        return None

    operations = []
    insertion_count = 0
    cursor = 1
    for _ in range(operation_count):
        if cursor >= len(values):
            return None
        kind = values[cursor]
        cursor += 1
        if kind == 0 or kind == 2:
            if cursor >= len(values):
                return None
            value = values[cursor]
            cursor += 1
            if not 0 <= value <= MAX_VALUE:
                return None
            if kind == 0:
                insertion_count += 1
                if insertion_count > MAX_INSERTIONS:
                    return None
            operations.append((kind, value))
        elif kind == 1:
            operations.append((kind, None))
        else:
            return None
    if cursor != len(values):
        return None
    return operations


def expected_output(values, output_capacity=None, output_is_null=False,
                    input_is_null=False, input_length=None):
    """Enumerate all subset XORs after each insert, then answer queries."""
    operations = _parse(values, input_is_null, input_length)
    if operations is None:
        return -1, b""

    reachable = [0]
    reachable_set = {0}
    results = []
    for kind, value in operations:
        if kind == 0:
            additions = [subset_xor ^ value for subset_xor in reachable]
            reachable.extend(additions)
            reachable_set.update(additions)
        elif kind == 1:
            results.append(max(reachable))
        else:
            results.append(1 if value in reachable_set else 0)
    payload = b"".join(struct.pack("<q", result) for result in results)

    capacity = MAX_OUTPUT_BYTES if output_capacity is None else output_capacity
    if (type(output_is_null) is not bool or type(capacity) is not int
            or capacity < 0):
        return -2, b""
    if payload and (output_is_null or capacity < len(payload)):
        return -2, b""
    return len(payload), payload
