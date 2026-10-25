"""Independent oracle for the bounded TSVC s1221 lag-four recurrence."""

from __future__ import annotations

import struct
from collections.abc import Sequence

MIN_N = 5
MAX_N = 32
MAX_INPUT_LENGTH = 1 + 2 * MAX_N
MAX_OUTPUT_BYTES = 8 * MAX_N
MAX_VALUE = 10
I64_MIN = -(1 << 63)
I64_MAX = (1 << 63) - 1


def expected_output(
    values: Sequence[int] | None,
    output_capacity: int | None = None,
    output_is_null: bool = False,
    input_is_null: bool = False,
    input_length: int | None = None,
) -> tuple[int, bytes]:
    """Return B after applying each residue-class recurrence from A."""
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
    if input_is_null or values is None or not 1 + 2 * MIN_N <= len(values) <= MAX_INPUT_LENGTH:
        return -1, b""
    if input_length is not None and input_length != len(values):
        return -1, b""
    if any(type(value) is not int or not I64_MIN <= value <= I64_MAX for value in values):
        return -1, b""

    n = values[0]
    if not MIN_N <= n <= MAX_N or len(values) != 1 + 2 * n:
        return -1, b""
    a = values[1:1 + n]
    b = list(values[1 + n:])
    if any(value < -MAX_VALUE or value > MAX_VALUE for value in (*a, *b)):
        return -1, b""
    if output_is_null or output_capacity is not None and output_capacity < 8 * n:
        return -2, b""

    # Each residue class modulo four is an independent chain. Compute the
    # dependency directly from already-produced B values in that class.
    for i in range(4, n):
        b[i] = b[i - 4] + a[i]
    return n, b"".join(struct.pack("<q", value) for value in b)
