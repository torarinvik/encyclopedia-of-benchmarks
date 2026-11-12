"""Direct nested-loop oracle for bounded modular polynomial convolution."""

from collections.abc import Sequence
import struct

MODULUS = 998_244_353
MAX_LENGTH = 256
MAX_NTT_SIZE = 512
MAX_PARSEABLE_INPUT_LENGTH = 2 + 2 * MAX_LENGTH
MAX_OUTPUT_BYTES = (2 * MAX_LENGTH - 1) * 8
MAX_WORKSPACE_BYTES = 2 * MAX_NTT_SIZE * 8


def expected_output(values: Sequence[int] | None, capacity: int | None = None,
                    output_is_null: bool = False, input_is_null: bool = False,
                    input_length: int | None = None) -> tuple[int, bytes]:
    """Return ``(result, bytes)`` for ``[N, M, a..., b...]``."""
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
    n, m = values[:2]
    if not 1 <= n <= MAX_LENGTH or not 1 <= m <= MAX_LENGTH:
        return -1, b""
    if len(values) != 2 + n + m:
        return -1, b""
    a = values[2:2 + n]
    b = values[2 + n:]
    if any(not 0 <= coefficient < MODULUS for coefficient in (*a, *b)):
        return -1, b""

    result = [0] * (n + m - 1)
    for left_index, left_value in enumerate(a):
        for right_index, right_value in enumerate(b):
            index = left_index + right_index
            result[index] = (result[index] + left_value * right_value) % MODULUS
    encoded = b"".join(struct.pack("<q", coefficient) for coefficient in result)

    required_bytes = 8 * len(result)
    effective_capacity = required_bytes if capacity is None else capacity
    if output_is_null or effective_capacity < required_bytes:
        return -2, b""
    return required_bytes, encoded
