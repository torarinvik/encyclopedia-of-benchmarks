"""Direct pair-enumeration oracle for bounded bitwise-AND convolution."""

from collections.abc import Sequence
import struct

MODULUS = 998_244_353
MAX_N = 8
MAX_SIZE = 1 << MAX_N
MAX_PARSEABLE_INPUT_LENGTH = 1 + 2 * MAX_SIZE
MAX_OUTPUT_BYTES = 8 * MAX_SIZE


def expected_output(values: Sequence[int] | None, capacity: int | None = None,
                    output_is_null: bool = False, input_is_null: bool = False,
                    input_length: int | None = None) -> tuple[int, bytes]:
    """Return ``(result, bytes)`` for ``[N, a[2^N], b[2^N]]``."""
    if (type(output_is_null) is not bool or type(input_is_null) is not bool
            or (capacity is not None and (type(capacity) is not int or capacity < 0))
            or (input_length is not None
                and (type(input_length) is not int
                     or not 0 <= input_length <= MAX_PARSEABLE_INPUT_LENGTH))):
        return -1, b""
    if input_is_null or values is None or not isinstance(values, (list, tuple)):
        return -1, b""
    if (len(values) < 1 or len(values) > MAX_PARSEABLE_INPUT_LENGTH
            or (input_length is not None and input_length != len(values))
            or any(type(value) is not int or not -(1 << 63) <= value < (1 << 63)
                   for value in values)):
        return -1, b""
    n = values[0]
    if not 0 <= n <= MAX_N:
        return -1, b""
    size = 1 << n
    if len(values) != 1 + 2 * size:
        return -1, b""
    a = values[1:1 + size]
    b = values[1 + size:]
    if any(not 0 <= value < MODULUS for value in (*a, *b)):
        return -1, b""

    result = [0] * size
    for left_index, left_value in enumerate(a):
        for right_index, right_value in enumerate(b):
            output_index = left_index & right_index
            result[output_index] = (
                result[output_index] + left_value * right_value
            ) % MODULUS
    encoded = b"".join(struct.pack("<q", value) for value in result)

    required_bytes = 8 * size
    effective_capacity = required_bytes if capacity is None else capacity
    if output_is_null or effective_capacity < required_bytes:
        return -2, b""
    return required_bytes, encoded
