"""Oracle for the bounded integer STREAM-vector kernel variant."""
from __future__ import annotations

import struct
from typing import Sequence

MIN_N = 0
MAX_N = 128
MAX_PARSEABLE_INPUT_LENGTH = 259
MIN_VALUE = -1000
MAX_VALUE = 1000
I64_MIN = -(1 << 63)
I64_MAX = (1 << 63) - 1
INVALID_RESULT = -1
OUTPUT_ERROR = -2


def expected_output(
    values: Sequence[int] | None,
    output_capacity: int | None = None,
    output_is_null: bool = False,
    input_is_null: bool = False,
    input_length: int | None = None,
) -> tuple[int, bytes]:
    """Return the status and output bytes for one mode-selected kernel call."""
    if (type(output_is_null) is not bool or type(input_is_null) is not bool
            or (output_capacity is not None
                and (type(output_capacity) is not int or output_capacity < 0))
            or (input_length is not None
                and (type(input_length) is not int or input_length < 0))):
        return INVALID_RESULT, b""
    if (input_is_null or values is None or not isinstance(values, (list, tuple))
            or not 2 <= len(values) <= MAX_PARSEABLE_INPUT_LENGTH
            or (input_length is not None and input_length != len(values))
            or any(type(value) is not int or not I64_MIN <= value <= I64_MAX
                   for value in values)):
        return INVALID_RESULT, b""

    mode, count = values[0], values[1]
    if mode not in range(4) or not MIN_N <= count <= MAX_N:
        return INVALID_RESULT, b""

    has_alpha = mode in (1, 3)
    array_count = 1 if mode in (0, 1) else 2
    expected_length = 2 + int(has_alpha) + array_count * count
    if len(values) != expected_length:
        return INVALID_RESULT, b""

    offset = 2
    alpha = 0
    if has_alpha:
        alpha = values[offset]
        offset += 1
        if not MIN_VALUE <= alpha <= MAX_VALUE:
            return INVALID_RESULT, b""
    arrays: list[list[int]] = []
    for _ in range(array_count):
        array = list(values[offset:offset + count])
        if any(value < MIN_VALUE or value > MAX_VALUE for value in array):
            return INVALID_RESULT, b""
        arrays.append(array)
        offset += count

    result: list[int] = []
    for index in range(count):
        if mode == 0:
            value = arrays[0][index]
        elif mode == 1:
            value = alpha * arrays[0][index]
        elif mode == 2:
            value = arrays[0][index] + arrays[1][index]
        else:
            value = arrays[0][index] + alpha * arrays[1][index]
        if not I64_MIN <= value <= I64_MAX:
            return INVALID_RESULT, b""
        result.append(value)

    output = b"".join(struct.pack("<q", value) for value in result)
    if output_is_null or (output_capacity is not None and output_capacity < len(output)):
        return OUTPUT_ERROR, b""
    return len(output), output
