"""Independent oracle for the bounded TSVC s116 profile."""
from __future__ import annotations

import struct
from collections.abc import Sequence

MAX_BLOCKS = 4
MAX_N = 5 * MAX_BLOCKS + 1
MAX_PASSES = 4
MAX_INPUT_LENGTH = 2 + MAX_N
MAX_OUTPUT_BYTES = 8 * MAX_N
I64_MIN = -(1 << 63)
I64_MAX = (1 << 63) - 1


def expected_output(values: Sequence[int] | None, output_capacity: int | None = None,
                    output_is_null: bool = False, input_is_null: bool = False,
                    input_length: int | None = None) -> tuple[int, bytes]:
    if (not isinstance(values, (list, tuple)) or type(output_is_null) is not bool
            or type(input_is_null) is not bool
            or output_capacity is not None and (type(output_capacity) is not int or output_capacity < 0)
            or input_length is not None and (type(input_length) is not int or input_length < 0 or input_length > MAX_INPUT_LENGTH)
            or any(type(x) is not int or x < I64_MIN or x > I64_MAX for x in values)):
        return -1, b""
    if input_is_null or len(values) < 8 or len(values) > MAX_INPUT_LENGTH:
        return -1, b""
    if input_length is not None and input_length != len(values):
        return -1, b""
    n, passes = values[0], values[1]
    if not 6 <= n <= MAX_N or (n - 1) % 5 or not 1 <= passes <= MAX_PASSES or len(values) != 2 + n:
        return -1, b""
    a = list(values[2:])
    if any(x not in (-1, 1) for x in a):
        return -1, b""
    if output_is_null or output_capacity is not None and output_capacity < 8 * n:
        return -2, b""
    for _ in range(passes):
        i = 0
        while i < n - 5:
            # Keep the five source assignments sequential: each reads the updated neighbor.
            a[i] = a[i + 1] * a[i]
            a[i + 1] = a[i + 2] * a[i + 1]
            a[i + 2] = a[i + 3] * a[i + 2]
            a[i + 3] = a[i + 4] * a[i + 3]
            a[i + 4] = a[i + 5] * a[i + 4]
            i += 5
    return n, b"".join(struct.pack("<q", x) for x in a)
