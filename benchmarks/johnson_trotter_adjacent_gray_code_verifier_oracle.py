"""Independent recursive reflected-insertion verifier for SJT output."""

from __future__ import annotations

import struct
from collections.abc import Sequence

MAX_INPUT_LENGTH = 2
MAX_OUTPUT_BYTES = 144


def _parse(data: Sequence[int] | None):
    if not isinstance(data, (list, tuple)) or len(data) != 1:
        return None
    if type(data[0]) is not int or data[0] < 1 or data[0] > 3:
        return None
    return data[0]


def _recursive_gray_code(n: int) -> tuple[tuple[int, ...], ...]:
    if n == 1:
        return ((1,),)
    smaller = _recursive_gray_code(n - 1)
    result = []
    for rank, row in enumerate(smaller):
        positions = range(n - 1, -1, -1) if rank % 2 == 0 else range(n)
        for position in positions:
            result.append(row[:position] + (n,) + row[position:])
    return tuple(result)


def expected_output(values: Sequence[int] | None, capacity: int | None = None,
                    output_is_null: bool = False, input_is_null: bool = False,
                    input_length: int | None = None) -> tuple[int, bytes]:
    if (type(output_is_null) is not bool or type(input_is_null) is not bool
            or capacity is not None and (type(capacity) is not int or capacity < 0)
            or input_length is not None and (type(input_length) is not int
                                             or not 0 <= input_length <= MAX_INPUT_LENGTH)
            or input_is_null and values not in (None, [], ())
            or not input_is_null and values is not None and input_length is not None
            and input_length != len(values)):
        return -1, b""
    if input_is_null or values is None:
        return -1, b""
    n = _parse(values)
    if n is None:
        return -1, b""
    rows = _recursive_gray_code(n)
    payload = struct.pack("<" + "q" * (n * len(rows)), *(value for row in rows for value in row))
    if output_is_null or capacity is not None and capacity < len(payload):
        return -2, b""
    return len(payload), payload
