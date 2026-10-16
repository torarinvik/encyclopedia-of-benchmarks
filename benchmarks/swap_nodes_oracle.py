"""Bounded oracle for first-match linked-list data swapping."""

import struct


MIN_N = 0
MAX_N = 64
MIN_I32 = -(1 << 31)
MAX_I32 = (1 << 31) - 1
MAX_INPUT_LENGTH = MAX_N + 3
MAX_OUTPUT_BYTES = 8 + MAX_N * 8
I64_MIN = -(1 << 63)
I64_MAX = (1 << 63) - 1


def expected_result(values, output_capacity=MAX_OUTPUT_BYTES):
    if (not isinstance(values, (list, tuple)) or len(values) < 3
            or any(type(value) is not int or not I64_MIN <= value <= I64_MAX
                   for value in values)):
        return -1, b""

    n = values[0]
    if not MIN_N <= n <= MAX_N or len(values) != n + 3:
        return -1, b""

    items = list(values[1:1 + n])
    value_a, value_b = values[-2:]
    if any(not MIN_I32 <= value <= MAX_I32
           for value in (*items, value_a, value_b)):
        return -1, b""

    if value_a != value_b:
        try:
            index_a = items.index(value_a)
            index_b = items.index(value_b)
        except ValueError:
            pass
        else:
            items[index_a], items[index_b] = items[index_b], items[index_a]

    output = struct.pack("<q", n) + b"".join(
        struct.pack("<q", value) for value in items
    )
    if output_capacity < len(output):
        return -2, b""
    return len(output), output
