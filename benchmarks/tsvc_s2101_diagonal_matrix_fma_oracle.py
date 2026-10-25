"""Independent oracle for a bounded TSVC s2101 diagonal matrix FMA."""

from __future__ import annotations

import struct
from collections.abc import Sequence

MAX_N = 8
MAX_MATRIX_VALUES = MAX_N * MAX_N
MAX_INPUT_LENGTH = 1 + 3 * MAX_MATRIX_VALUES
MAX_VALUE = 100
MAX_OUTPUT_CAPACITY = 8 * MAX_MATRIX_VALUES
I64_MIN = -(1 << 63)
I64_MAX = (1 << 63) - 1


def expected_output(
    values: Sequence[int] | None,
    output_capacity: int | None = None,
    output_is_null: bool = False,
    input_is_null: bool = False,
    input_length: int | None = None,
) -> tuple[int, bytes]:
    """Update only the main diagonal of AA and encode the full result matrix."""
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
    if input_is_null or values is None or not 2 <= len(values) <= MAX_INPUT_LENGTH:
        return -1, b""
    if input_length is not None and input_length != len(values):
        return -1, b""
    if any(type(value) is not int or not I64_MIN <= value <= I64_MAX for value in values):
        return -1, b""

    n = values[0]
    if not 1 <= n <= MAX_N:
        return -1, b""
    cells = n * n
    if len(values) != 1 + 3 * cells:
        return -1, b""
    aa = list(values[1 : 1 + cells])
    bb = values[1 + cells : 1 + 2 * cells]
    cc = values[1 + 2 * cells :]
    if any(not -MAX_VALUE <= value <= MAX_VALUE for value in (*aa, *bb, *cc)):
        return -1, b""
    if output_is_null or output_capacity is not None and output_capacity < 8 * cells:
        return -2, b""

    for i in range(n):
        diagonal = i * n + i
        aa[diagonal] += bb[diagonal] * cc[diagonal]
    return cells, struct.pack("<" + "q" * cells, *aa)
