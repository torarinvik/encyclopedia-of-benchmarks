"""Independent oracle for the bounded TSVC s244 node-splitting kernel."""

from __future__ import annotations

import struct
from collections.abc import Sequence

MAX_N = 32
MIN_N = 2
MAX_INPUT_LENGTH = 1 + 4 * MAX_N
MAX_OUTPUT_VALUES = 3 * MAX_N - 1
MAX_OUTPUT_BYTES = 8 * MAX_OUTPUT_VALUES
MAX_VALUE = 2
I64_MIN = -(1 << 63)
I64_MAX = (1 << 63) - 1


def expected_output(
    values: Sequence[int] | None,
    output_capacity: int | None = None,
    output_is_null: bool = False,
    input_is_null: bool = False,
    input_length: int | None = None,
) -> tuple[int, bytes]:
    """Return final arrays plus third-statement values captured before overwrite."""
    if (
        values is not None and not isinstance(values, (list, tuple))
        or type(output_is_null) is not bool
        or type(input_is_null) is not bool
        or output_capacity is not None
        and (type(output_capacity) is not int or output_capacity < 0)
        or input_length is not None
        and (type(input_length) is not int or not 0 <= input_length <= MAX_INPUT_LENGTH)
    ):
        return -1, b""
    if input_is_null or values is None or not 1 + 4 * MIN_N <= len(values) <= MAX_INPUT_LENGTH:
        return -1, b""
    if input_length is not None and input_length != len(values):
        return -1, b""
    if any(type(value) is not int or not I64_MIN <= value <= I64_MAX for value in values):
        return -1, b""

    n = values[0]
    if not MIN_N <= n <= MAX_N or len(values) != 1 + 4 * n:
        return -1, b""
    a_initial = values[1:1 + n]
    b_initial = values[1 + n:1 + 2 * n]
    c = values[1 + 2 * n:1 + 3 * n]
    d = values[1 + 3 * n:]
    if any(value < -MAX_VALUE or value > MAX_VALUE for value in (*a_initial, *b_initial, *c, *d)):
        return -1, b""

    required_bytes = 8 * (3 * n - 1)
    if output_is_null or output_capacity is not None and output_capacity < required_bytes:
        return -2, b""

    # Each iteration's third store uses the newly updated B[i] and the old
    # A[i+1]. The next iteration overwrites that A slot, except at the tail.
    trace = [b_initial[i] + c[i] + a_initial[i + 1] * d[i] for i in range(n - 1)]
    final_a = [b_initial[i] + c[i] * d[i] for i in range(n - 1)] + [trace[-1]]
    final_b = [b_initial[i] + c[i] for i in range(n - 1)] + [b_initial[-1]]
    result = (*final_a, *final_b, *trace)
    return len(result), b"".join(struct.pack("<q", value) for value in result)
