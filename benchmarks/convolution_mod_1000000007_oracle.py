"""Direct exact-integer oracle for bounded convolution modulo 1,000,000,007."""

from collections.abc import Sequence
import struct

MODULUS = 1_000_000_007
MAX_LENGTH = 64
MAX_NTT_SIZE = 128
MAX_PARSEABLE_INPUT_LENGTH = 2 + 2 * MAX_LENGTH
MAX_OUTPUT_BYTES = (2 * MAX_LENGTH - 1) * 8
MAX_WORKSPACE_BYTES = 5 * MAX_NTT_SIZE * 8


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
    left = values[2:2 + n]
    right = values[2 + n:]
    if any(not 0 <= coefficient < MODULUS for coefficient in (*left, *right)):
        return -1, b""

    coefficients = [0] * (n + m - 1)
    for i, a in enumerate(left):
        for j, b in enumerate(right):
            coefficients[i + j] = (coefficients[i + j] + a * b) % MODULUS
    encoded = b"".join(struct.pack("<q", coefficient) for coefficient in coefficients)
    required_bytes = len(encoded)
    effective_capacity = required_bytes if capacity is None else capacity
    if output_is_null or effective_capacity < required_bytes:
        return -2, b""
    return required_bytes, encoded
