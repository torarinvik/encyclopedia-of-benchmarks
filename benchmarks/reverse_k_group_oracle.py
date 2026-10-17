"""Independent array-based oracle for the bounded reverse-k-group ABI."""
from __future__ import annotations

import struct

MAX_N = 256
MAX_K = 256
MAX_VALID_INPUT_LENGTH = MAX_N + 2
MAX_PARSEABLE_INPUT_LENGTH = MAX_VALID_INPUT_LENGTH + 1
I64_MIN = -(1 << 63)
I64_MAX = (1 << 63) - 1


def expected_output(
    values: list[int] | tuple[int, ...] | None,
    output_capacity: int | None = None,
    output_is_null: bool = False,
    input_is_null: bool = False,
    input_length: int | None = None,
) -> tuple[int, bytes]:
    if type(input_is_null) is not bool:
        return -1, b""
    if input_is_null:
        if ((values is not None and values != [] and values != ())
                or type(input_length) is not int
                or not 1 <= input_length <= MAX_PARSEABLE_INPUT_LENGTH):
            return -1, b""
        return -1, b""
    if values is None:
        return -1, b""
    if not isinstance(values, (list, tuple)) or len(values) < 2:
        return -1, b""
    if (len(values) > MAX_PARSEABLE_INPUT_LENGTH
            or (input_length is not None
                and (type(input_length) is not int or input_length != len(values)))):
        return -1, b""
    if any(type(value) is not int or not I64_MIN <= value <= I64_MAX for value in values):
        return -1, b""
    n, k = values[0], values[1]
    if n < 0 or n > MAX_N or k < 1 or k > MAX_K or len(values) != n + 2:
        return -1, b""
    if type(output_is_null) is not bool:
        return -1, b""
    if output_capacity is not None and (
        type(output_capacity) is not int or output_capacity < 0
    ):
        return -1, b""

    result = list(values[2:])
    for start in range(0, n, k):
        end = start + k
        if end <= n:
            result[start:end] = reversed(result[start:end])
    encoded = b"".join(struct.pack("<q", value) for value in result)
    if output_is_null or (output_capacity is not None and output_capacity < len(encoded)):
        return -2, b""
    return len(encoded), encoded
