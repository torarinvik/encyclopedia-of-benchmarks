"""Primary bounded oracle using in-place descending Horner composition."""

from __future__ import annotations

from collections.abc import Sequence
import struct

MODULUS = 998_244_353
MAX_N = 16
MAX_INPUT_LENGTH = 34
MAX_OUTPUT_BYTES = 128
I64_MIN = -(1 << 63)
I64_MAX = (1 << 63) - 1


def _invalid() -> tuple[int, bytes]:
    return -1, b""


def expected_output(
    values: Sequence[int] | None,
    output_capacity: int | None = None,
    output_is_null: bool = False,
    input_is_null: bool = False,
    input_length: int | None = None,
) -> tuple[int, bytes]:
    if type(output_is_null) is not bool or type(input_is_null) is not bool:
        return _invalid()
    if input_is_null or not isinstance(values, (list, tuple)):
        return _invalid()
    if len(values) < 3 or len(values) > MAX_INPUT_LENGTH:
        return _invalid()
    if input_length is not None and (type(input_length) is not int or input_length != len(values)):
        return _invalid()
    if any(type(value) is not int or not I64_MIN <= value <= I64_MAX for value in values):
        return _invalid()
    n = values[0]
    if not 1 <= n <= MAX_N or len(values) != 1 + 2 * n:
        return _invalid()
    first = values[1:1 + n]
    inner = values[1 + n:]
    if (any(not 0 <= value < MODULUS for value in first)
            or any(not 0 <= value < MODULUS for value in inner) or inner[0] != 0):
        return _invalid()

    byte_count = 8 * n
    if output_is_null or (output_capacity is not None and
                          (type(output_capacity) is not int or output_capacity < byte_count)):
        return -2, b""

    composed = [0] * n
    for coefficient in reversed(first):
        for degree in range(n - 1, 0, -1):
            total = 0
            for inner_degree in range(1, degree + 1):
                total = (total + composed[degree - inner_degree] * inner[inner_degree]) % MODULUS
            composed[degree] = total
        composed[0] = coefficient
    encoded = b"".join(struct.pack("<q", value) for value in composed)
    return byte_count, encoded
