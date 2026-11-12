"""Direct subtree-traversal oracle for the bounded vertex-add workload."""

from __future__ import annotations

import struct

MAX_N = 128
MAX_Q = 256
MAX_VALUE = 1_000_000
MAX_VALID_INPUT_LENGTH = 2 * MAX_N + 1 + 3 * MAX_Q
MAX_PARSEABLE_INPUT_LENGTH = MAX_VALID_INPUT_LENGTH + 1
MAX_OUTPUT_BYTES = 8 * MAX_Q


def expected_output(values, capacity=None, output_is_null=False,
                    input_is_null=False, input_length=None):
    """Return ``(result, bytes)``; subtree answers use direct child traversal."""
    if input_is_null or not isinstance(values, (list, tuple)):
        return -1, b""
    if input_length is None:
        input_length = len(values)
    if (type(input_length) is not int or input_length < 0
            or input_length > MAX_PARSEABLE_INPUT_LENGTH
            or input_length != len(values) or len(values) < 2):
        return -1, b""
    if any(type(value) is not int or not -(1 << 63) <= value < (1 << 63)
           for value in values):
        return -1, b""

    n, q = values[:2]
    if not 1 <= n <= MAX_N or not 0 <= q <= MAX_Q:
        return -1, b""
    if len(values) != 2 * n + 1 + 3 * q:
        return -1, b""

    vertex_values = list(values[2:2 + n])
    if any(not 0 <= value <= MAX_VALUE for value in vertex_values):
        return -1, b""

    parent_start = 2 + n
    children = [[] for _ in range(n)]
    for vertex in range(1, n):
        parent = values[parent_start + vertex - 1]
        if not 0 <= parent < vertex:
            return -1, b""
        children[parent].append(vertex)

    operation_start = parent_start + n - 1
    operations = []
    query_count = 0
    for index in range(q):
        offset = operation_start + 3 * index
        kind, vertex, operand = values[offset:offset + 3]
        if kind == 0:
            if not 0 <= vertex < n or not 0 <= operand <= MAX_VALUE:
                return -1, b""
        elif kind == 1:
            if not 0 <= vertex < n or operand != 0:
                return -1, b""
            query_count += 1
        else:
            return -1, b""
        operations.append((kind, vertex, operand))

    answers = []
    for kind, vertex, operand in operations:
        if kind == 0:
            vertex_values[vertex] += operand
        else:
            pending = [vertex]
            total = 0
            while pending:
                current = pending.pop()
                total += vertex_values[current]
                pending.extend(children[current])
            answers.append(total)

    required = 8 * query_count
    effective_capacity = MAX_OUTPUT_BYTES if capacity is None else capacity
    if (type(output_is_null) is not bool or type(effective_capacity) is not int
            or effective_capacity < 0):
        return -2, b""
    if required > 0 and (output_is_null or effective_capacity < required):
        return -2, b""
    output = b"".join(struct.pack("<q", answer) for answer in answers)
    return len(output), output
