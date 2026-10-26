"""Independent oracle for the bounded TSVC s1213 ordered two-array map."""
from __future__ import annotations
import struct
from collections.abc import Sequence

MAX_N = 32
MAX_INPUT_LENGTH = 1 + 4 * MAX_N
MAX_OUTPUT_BYTES = 16 * MAX_N
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
    if input_is_null or len(values) < 13 or len(values) > MAX_INPUT_LENGTH:
        return -1, b""
    if input_length is not None and input_length != len(values):
        return -1, b""
    n = values[0]
    if not 3 <= n <= MAX_N or len(values) != 1 + 4 * n:
        return -1, b""
    a = list(values[1:1+n])
    b = list(values[1+n:1+2*n])
    c = values[1+2*n:1+3*n]
    d = values[1+3*n:]
    if any(x < -1 or x > 1 for x in (*a, *b, *c, *d)):
        return -1, b""
    if output_is_null or output_capacity is not None and output_capacity < 16*n:
        return -2, b""
    for i in range(1, n-1):
        a[i] = b[i-1] + c[i]
        b[i] = a[i+1] * d[i]
    out = (*a, *b)
    return 2*n, b"".join(struct.pack("<q", x) for x in out)
