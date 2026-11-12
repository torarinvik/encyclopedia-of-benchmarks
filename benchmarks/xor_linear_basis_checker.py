"""Independent bitmask-enumeration checker for XOR-basis query results."""

from __future__ import annotations

import struct

MAX_OPERATIONS = 64
MAX_INSERTIONS = 16
MAX_VALUE = (1 << 63) - 1
MAX_PARSEABLE_INPUT_LENGTH = 1 + 2 * MAX_OPERATIONS + 1
MAX_OUTPUT_BYTES = 8 * MAX_OPERATIONS


def parse_operations(values, input_is_null=False, input_length=None):
    if input_is_null or not isinstance(values, (list, tuple)):
        return None
    if input_length is None:
        input_length = len(values)
    if (type(input_length) is not int or input_length != len(values)
            or not 2 <= input_length <= MAX_PARSEABLE_INPUT_LENGTH):
        return None
    if any(type(word) is not int or not -(1 << 63) <= word < (1 << 63)
           for word in values):
        return None
    q = values[0]
    if not 1 <= q <= MAX_OPERATIONS:
        return None
    operations = []
    inserts = 0
    pos = 1
    for _ in range(q):
        if pos >= len(values):
            return None
        kind = values[pos]
        pos += 1
        if kind in (0, 2):
            if pos >= len(values):
                return None
            value = values[pos]
            pos += 1
            if not 0 <= value <= MAX_VALUE:
                return None
            if kind == 0:
                inserts += 1
                if inserts > MAX_INSERTIONS:
                    return None
            operations.append((kind, value))
        elif kind == 1:
            operations.append((kind, None))
        else:
            return None
    if pos != len(values):
        return None
    return operations


def _all_subset_xors(inserted):
    values = set()
    for mask in range(1 << len(inserted)):
        current = 0
        for bit, value in enumerate(inserted):
            if mask & (1 << bit):
                current ^= value
        values.add(current)
    return values


def expected_output(values, output_capacity=None, output_is_null=False,
                    input_is_null=False, input_length=None):
    operations = parse_operations(values, input_is_null, input_length)
    if operations is None:
        return -1, b""
    inserted = []
    results = []
    for kind, value in operations:
        if kind == 0:
            inserted.append(value)
        else:
            reachable = _all_subset_xors(inserted)
            if kind == 1:
                results.append(max(reachable))
            else:
                results.append(1 if value in reachable else 0)
    payload = b"".join(struct.pack("<q", result) for result in results)
    capacity = MAX_OUTPUT_BYTES if output_capacity is None else output_capacity
    if (type(output_is_null) is not bool or type(capacity) is not int
            or capacity < 0):
        return -2, b""
    if payload and (output_is_null or capacity < len(payload)):
        return -2, b""
    return len(payload), payload


def verify_result(values, result, output, **abi_options):
    return (result, output) == expected_output(values, **abi_options)
