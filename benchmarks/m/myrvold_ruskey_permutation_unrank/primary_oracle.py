"""Mixed-radix Fisher–Yates unranking reference (Myrvold–Ruskey Algorithm 1)."""

from __future__ import annotations

import struct

MIN_N = 0
MAX_N = 8
MAX_VALID_INPUT_LENGTH = 2
MAX_PARSEABLE_INPUT_LENGTH = 3
MAX_OUTPUT_BYTES = 64
WORKSPACE_BYTES = 256
I64_MIN = -(1 << 63)
I64_MAX = (1 << 63) - 1


def permutation(n: int, rank: int) -> list[int]:
    """Unrank by recursively determined Fisher–Yates choices, iteratively."""
    result = list(range(n))
    remainder = rank
    size = n
    while size > 0:
        choice = remainder % size
        remainder //= size
        last = size - 1
        result[last], result[choice] = result[choice], result[last]
        size -= 1
    return result


def _decode(values, input_is_null: bool, input_length: int | None):
    if (type(input_is_null) is not bool or input_is_null
            or not isinstance(values, (tuple, list))
            or len(values) > MAX_PARSEABLE_INPUT_LENGTH
            or any(type(value) is not int or not I64_MIN <= value <= I64_MAX
                   for value in values)):
        return None
    if input_length is not None and (
            type(input_length) is not int
            or input_length != len(values)
            or not 0 <= input_length <= MAX_PARSEABLE_INPUT_LENGTH):
        return None
    if len(values) != MAX_VALID_INPUT_LENGTH:
        return None
    n, rank = values
    if not MIN_N <= n <= MAX_N:
        return None
    factorial = 1
    for factor in range(2, n + 1):
        factorial *= factor
    if not 0 <= rank < factorial:
        return None
    return n, rank


def expected_output(
    values: list[int] | tuple[int, ...] | None,
    output_capacity: int | None = None,
    output_is_null: bool = False,
    input_is_null: bool = False,
    input_length: int | None = None,
) -> tuple[int, bytes]:
    """Return `(byte-count-or-error, little-endian i64 permutation bytes)`."""
    if (type(output_is_null) is not bool
            or output_capacity is not None
            and (type(output_capacity) is not int or output_capacity < 0)
            or type(input_is_null) is not bool
            or input_length is not None
            and (type(input_length) is not int
                 or not 0 <= input_length <= MAX_PARSEABLE_INPUT_LENGTH)):
        return -1, b""
    if input_is_null:
        if values not in (None, [], ()) or input_length not in (None, 0):
            return -1, b""
        return -1, b""
    decoded = _decode(values, input_is_null, input_length)
    if decoded is None:
        return -1, b""
    n, rank = decoded
    required = 8 * n
    if output_is_null or (output_capacity is not None and output_capacity < required):
        return -2, b""
    result = permutation(n, rank)
    payload = struct.pack("<" + "q" * n, *result) if n else b""
    return required, payload
