"""Independent list-based oracle for bounded sqrt-decomposition range sums."""
from __future__ import annotations

import struct

MAX_N = 64
MAX_OPERATIONS = 64
MAX_INPUT_LENGTH = 2 + MAX_N + 3 * MAX_OPERATIONS
MAX_OUTPUT_BYTES = 8 * MAX_OPERATIONS
I64_MIN = -(1 << 63)
I64_MAX = (1 << 63) - 1
VALUE_MIN = -1000
VALUE_MAX = 1000


def expected_output(
    values: list[int] | tuple[int, ...],
    output_capacity: int | None = None,
    output_is_null: bool = False,
) -> tuple[int, bytes]:
    if (
        not isinstance(values, (list, tuple))
        or not 3 <= len(values) <= MAX_INPUT_LENGTH
        or any(type(value) is not int or not I64_MIN <= value <= I64_MAX for value in values)
    ):
        return -1, b""

    n = values[0]
    if not 1 <= n <= MAX_N:
        return -1, b""
    op_count_index = n + 1
    if op_count_index >= len(values):
        return -1, b""
    op_count = values[op_count_index]
    if not 0 <= op_count <= MAX_OPERATIONS:
        return -1, b""
    if len(values) != 2 + n + 3 * op_count:
        return -1, b""

    current = list(values[1 : n + 1])
    if any(not VALUE_MIN <= value <= VALUE_MAX for value in current):
        return -1, b""

    operations: list[tuple[int, int, int]] = []
    query_count = 0
    offset = n + 2
    for _ in range(op_count):
        kind, arg1, arg2 = values[offset : offset + 3]
        if kind == 0:
            if not 0 <= arg1 < arg2 <= n:
                return -1, b""
            query_count += 1
        elif kind == 1:
            if not 0 <= arg1 < n or not VALUE_MIN <= arg2 <= VALUE_MAX:
                return -1, b""
        else:
            return -1, b""
        operations.append((kind, arg1, arg2))
        offset += 3

    if type(output_is_null) is not bool:
        return -1, b""
    if output_capacity is not None and (
        type(output_capacity) is not int or output_capacity < 0
    ):
        return -1, b""
    required_bytes = query_count * 8
    if output_is_null or (output_capacity is not None and output_capacity < required_bytes):
        return -2, b""

    sums: list[int] = []
    for kind, arg1, arg2 in operations:
        if kind == 0:
            sums.append(sum(current[arg1:arg2]))
        else:
            current[arg1] = arg2
    encoded = b"".join(struct.pack("<q", result) for result in sums)
    return len(encoded), encoded
