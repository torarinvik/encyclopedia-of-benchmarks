"""Independent oracle for the bounded TSVC s353 sparse SAXPY gather."""

from __future__ import annotations

import struct
from collections.abc import Sequence

MIN_N = 5
MAX_N = 20
MAX_INPUT_LENGTH = 2 + 3 * MAX_N
MAX_OUTPUT_BYTES = 8 * MAX_N
MAX_VALUE = 1_000_000
MAX_ALPHA = 8
I64_MIN = -(1 << 63)
I64_MAX = (1 << 63) - 1


def expected_output(
    values: Sequence[int] | None,
    output_capacity: int | None = None,
    output_is_null: bool = False,
    input_is_null: bool = False,
    input_length: int | None = None,
) -> tuple[int, bytes]:
    """Return the updated A vector as little-endian signed i64 values."""
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
    if input_is_null or values is None or not 17 <= len(values) <= MAX_INPUT_LENGTH:
        return -1, b""
    if input_length is not None and input_length != len(values):
        return -1, b""
    if any(type(value) is not int or not I64_MIN <= value <= I64_MAX for value in values):
        return -1, b""

    n, alpha = values[0], values[1]
    if n < MIN_N or n > MAX_N or n % 5 != 0 or len(values) != 2 + 3 * n:
        return -1, b""
    if not -MAX_ALPHA <= alpha <= MAX_ALPHA:
        return -1, b""
    a = list(values[2:2 + n])
    b = list(values[2 + n:2 + 2 * n])
    indices = values[2 + 2 * n:]
    if any(value < -MAX_VALUE or value > MAX_VALUE for value in (*a, *b)):
        return -1, b""
    if any(index < 0 or index >= n for index in indices):
        return -1, b""
    if output_is_null or output_capacity is not None and output_capacity < 8 * n:
        return -2, b""

    # Independently express the observable mapping one destination at a time.
    # The bounded integer-valued double domain makes each multiply and add exact.
    result = [a[destination] + alpha * b[indices[destination]] for destination in range(n)]
    return n, b"".join(struct.pack("<q", value) for value in result)
