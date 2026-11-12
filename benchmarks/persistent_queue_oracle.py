"""Direct immutable-list oracle for branching persistent queue traces."""

from __future__ import annotations

import struct

MAX_Q = 128
MAX_VALUE = 1_000_000_000
MAX_VALID_INPUT_LENGTH = 1 + 3 * MAX_Q
MAX_PARSEABLE_INPUT_LENGTH = MAX_VALID_INPUT_LENGTH + 1
# The first version is empty, so at most Q-1 operations can pop an element.
MAX_OUTPUT_BYTES = 8 * (MAX_Q - 1)


def expected_output(values, capacity=None, output_is_null=False,
                    input_is_null=False, input_length=None):
    """Validate the operation stream and execute each version with Python lists."""
    if input_is_null or not isinstance(values, (list, tuple)):
        return -1, b""
    effective_length = len(values) if input_length is None else input_length
    if (type(effective_length) is not int or effective_length < 1
            or effective_length > MAX_PARSEABLE_INPUT_LENGTH
            or effective_length != len(values)
            or any(type(value) is not int or not -(1 << 63) <= value < (1 << 63)
                   for value in values)):
        return -1, b""

    q = values[0]
    if not 1 <= q <= MAX_Q:
        return -1, b""
    cursor = 1
    versions = [[]]
    answer_values = []
    query_count = 0
    for operation in range(q):
        if cursor >= len(values):
            return -1, b""
        kind = values[cursor]
        cursor += 1
        if cursor >= len(values):
            return -1, b""
        parent = values[cursor]
        cursor += 1
        if not -1 <= parent < operation:
            return -1, b""
        base = versions[parent + 1]
        if kind == 0:
            if cursor >= len(values):
                return -1, b""
            value = values[cursor]
            cursor += 1
            if not 0 <= value <= MAX_VALUE:
                return -1, b""
            versions.append([*base, value])
        elif kind == 1:
            if not base:
                return -1, b""
            answer_values.append(base[0])
            versions.append(base[1:])
            query_count += 1
        else:
            return -1, b""
    if cursor != len(values):
        return -1, b""

    payload = b"".join(struct.pack("<q", value) for value in answer_values)
    effective_capacity = MAX_OUTPUT_BYTES if capacity is None else capacity
    if (type(output_is_null) is not bool or type(effective_capacity) is not int
            or effective_capacity < 0):
        return -2, b""
    if query_count > 0 and (output_is_null or effective_capacity < len(payload)):
        return -2, b""
    return len(payload), payload
