"""Independent oracle for a bounded TSVC vag indexed gather-copy."""

from __future__ import annotations

import struct
from collections.abc import Sequence

MAX_N = 64
MAX_INPUT_LENGTH = 1 + 2 * MAX_N
MAX_VALUE = 1_000_000
I64_MIN = -(1 << 63)
I64_MAX = (1 << 63) - 1


def expected_output(
    values: Sequence[int] | None,
    output_capacity: int | None = None,
    output_is_null: bool = False,
    input_is_null: bool = False,
    input_length: int | None = None,
) -> tuple[int, bytes]:
    """Return B[index[i]] for each ascending output index i."""
    if (
        values is not None and not isinstance(values, (list, tuple))
        or type(output_is_null) is not bool
        or type(input_is_null) is not bool
        or output_capacity is not None
        and (type(output_capacity) is not int or output_capacity < 0)
        or input_length is not None
        and (type(input_length) is not int or input_length < 0 or input_length > MAX_INPUT_LENGTH)
    ):
        return -1, b""
    if input_is_null or values is None or not 3 <= len(values) <= MAX_INPUT_LENGTH:
        return -1, b""
    if input_length is not None and input_length != len(values):
        return -1, b""
    if any(type(value) is not int or not I64_MIN <= value <= I64_MAX for value in values):
        return -1, b""

    n = values[0]
    if not 1 <= n <= MAX_N or len(values) != 1 + 2 * n:
        return -1, b""
    indexes = values[1 : 1 + n]
    data = values[1 + n :]
    if any(not 0 <= index < n for index in indexes):
        return -1, b""
    if any(not -MAX_VALUE <= value <= MAX_VALUE for value in data):
        return -1, b""
    if output_is_null or output_capacity is not None and output_capacity < 8 * n:
        return -2, b""

    gathered = [data[index] for index in indexes]
    return n, struct.pack("<" + "q" * n, *gathered)
