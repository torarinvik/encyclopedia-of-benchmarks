"""Independent bounded oracle for TSVC s233/s2233 paired matrix recurrences."""
from __future__ import annotations
import struct
from collections.abc import Sequence

MAX_N = 8
MAX_INPUT_LENGTH = 2 + 3 * MAX_N * MAX_N
MAX_OUTPUT_BYTES = 16 * MAX_N * MAX_N
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
    if input_is_null or len(values) < 14 or len(values) > MAX_INPUT_LENGTH:
        return -1, b""
    if input_length is not None and input_length != len(values):
        return -1, b""
    n, mode = values[0], values[1]
    if not 2 <= n <= MAX_N or mode not in (0, 1) or len(values) != 2 + 3*n*n:
        return -1, b""
    nn = n*n
    a = list(values[2:2+nn])
    b = list(values[2+nn:2+2*nn])
    c = values[2+2*nn:]
    if any(x < -1 or x > 1 for x in (*a, *b, *c)):
        return -1, b""
    if output_is_null or output_capacity is not None and output_capacity < 16*nn:
        return -2, b""
    # Both sources first perform the same same-column A recurrence.
    for col in range(1, n):
        for row in range(1, n):
            a[row*n+col] = a[(row-1)*n+col] + c[row*n+col]
    if mode == 0:  # s233: outer column, inner row; B prefix runs horizontally.
        for col in range(1, n):
            for row in range(1, n):
                b[row*n+col] = b[row*n+col-1] + c[row*n+col]
    else:  # s2233: outer row, inner column; B prefix runs vertically.
        for row in range(1, n):
            for col in range(1, n):
                b[row*n+col] = b[(row-1)*n+col] + c[row*n+col]
    out = (*a, *b)
    return 2*nn, b"".join(struct.pack("<q", x) for x in out)
