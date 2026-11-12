"""Direct quadratic oracle for bounded convolution modulo 2^64."""

from collections.abc import Sequence
import struct

MASK = (1 << 64) - 1
MAX_LENGTH = 64
MAX_VALID_INPUT_LENGTH = 2 + 2 * MAX_LENGTH
MAX_PARSEABLE_INPUT_LENGTH = MAX_VALID_INPUT_LENGTH + 1
MAX_OUTPUT_BYTES = 8 * (2 * MAX_LENGTH - 1)


def expected_output(values: Sequence[int] | None, capacity: int | None = None,
                    output_is_null: bool = False, input_is_null: bool = False,
                    input_length: int | None = None) -> tuple[int, bytes]:
    """Return ``(status, bytes)`` for ``[N,M,a...,b...]``.

    Each signed i64 is interpreted as the raw two's-complement bit pattern of
    one unsigned 64-bit coefficient, so every ABI coefficient bit pattern is
    valid.
    """
    if (type(output_is_null) is not bool or type(input_is_null) is not bool
            or (capacity is not None and (type(capacity) is not int or capacity < 0))
            or (input_length is not None
                and (type(input_length) is not int
                     or not 0 <= input_length <= MAX_PARSEABLE_INPUT_LENGTH))):
        return -1, b""
    if input_is_null or values is None or not isinstance(values, (list, tuple)):
        return -1, b""
    if (len(values) < 2 or len(values) > MAX_PARSEABLE_INPUT_LENGTH
            or (input_length is not None and input_length != len(values))
            or any(type(value) is not int or not -(1 << 63) <= value < (1 << 63)
                   for value in values)):
        return -1, b""

    n, m = values[0], values[1]
    if not 1 <= n <= MAX_LENGTH or not 1 <= m <= MAX_LENGTH:
        return -1, b""
    if len(values) != 2 + n + m:
        return -1, b""

    left = [value & MASK for value in values[2:2 + n]]
    right = [value & MASK for value in values[2 + n:]]
    result = [0] * (n + m - 1)
    for i, left_value in enumerate(left):
        for j, right_value in enumerate(right):
            result[i + j] = (result[i + j] + left_value * right_value) & MASK
    encoded = b"".join(struct.pack("<Q", value) for value in result)

    required_bytes = 8 * len(result)
    effective_capacity = required_bytes if capacity is None else capacity
    if output_is_null or effective_capacity < required_bytes:
        return -2, b""
    return required_bytes, encoded
