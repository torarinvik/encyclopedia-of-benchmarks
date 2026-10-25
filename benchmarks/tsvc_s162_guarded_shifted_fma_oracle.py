"""Independent oracle for the bounded TSVC s162 guarded shifted FMA."""

from __future__ import annotations

import struct
from collections.abc import Sequence

MAX_N = 64
MAX_INPUT_LENGTH = 194
I64_MIN = -(1 << 63)
I64_MAX = (1 << 63) - 1
MIN_VALUE = -2
MAX_VALUE = 2


def expected_output(
    values: Sequence[int] | None,
    output_capacity: int | None = None,
    output_is_null: bool = False,
    input_is_null: bool = False,
    input_length: int | None = None,
) -> tuple[int, bytes]:
    """Return A after the guarded k=0/1 source-profile pass."""
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
    if input_is_null or values is None or not 5 <= len(values) <= MAX_INPUT_LENGTH:
        return -1, b""
    if input_length is not None and input_length != len(values):
        return -1, b""
    if any(type(value) is not int or not I64_MIN <= value <= I64_MAX for value in values):
        return -1, b""

    n, k = values[:2]
    if not 1 <= n <= MAX_N or k not in (0, 1):
        return -1, b""
    if len(values) != 2 + 3 * n:
        return -1, b""
    if any(not MIN_VALUE <= value <= MAX_VALUE for value in values[2:]):
        return -1, b""
    if output_is_null or output_capacity is not None and output_capacity < 8 * n:
        return -2, b""

    a = list(values[2:2 + n])
    b_offset = 2 + n
    c_offset = b_offset + n
    if k > 0:
        for i in range(n - 1):
            a[i] = values[2 + i + 1] + values[b_offset + i] * values[c_offset + i]
    return n, b"".join(struct.pack("<q", value) for value in a)
