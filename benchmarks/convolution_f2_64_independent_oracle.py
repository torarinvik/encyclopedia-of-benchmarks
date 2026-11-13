"""Independent polynomial-product and long-division oracle for GF(2^64)."""

from __future__ import annotations

from collections.abc import Sequence

try:
    from .convolution_f2_64_oracle import (
        MAX_M,
        MAX_N,
        MAX_OUTPUT_BYTES,
        MAX_PARSEABLE_INPUT_LENGTH,
    )
except ImportError:  # Direct execution from the benchmarks directory.
    from convolution_f2_64_oracle import (
        MAX_M,
        MAX_N,
        MAX_OUTPUT_BYTES,
        MAX_PARSEABLE_INPUT_LENGTH,
    )

U64_MASK = (1 << 64) - 1
MODULUS_POLYNOMIAL = (1 << 64) | 0x1B


def _field_product_by_remainder(left: int, right: int) -> int:
    raw = 0
    for bit in range(64):
        if (right >> bit) & 1:
            raw ^= left << bit
    for degree in range(126, 63, -1):
        if (raw >> degree) & 1:
            raw ^= MODULUS_POLYNOMIAL << (degree - 64)
    return raw & U64_MASK


def _parse(values: Sequence[int] | None, input_length: int | None,
           input_is_null: bool) -> tuple[list[int], list[int]] | None:
    if type(input_is_null) is not bool or input_is_null or not isinstance(values, (list, tuple)):
        return None
    if input_length is None:
        input_length = len(values)
    if (type(input_length) is not int or input_length < 2
            or input_length > MAX_PARSEABLE_INPUT_LENGTH
            or input_length != len(values)):
        return None
    if any(type(value) is not int or not -(1 << 63) <= value < (1 << 63)
           for value in values):
        return None
    n, m = values[0], values[1]
    if not 1 <= n <= MAX_N or not 1 <= m <= MAX_M or input_length != 2 + n + m:
        return None
    left = [value & U64_MASK for value in values[2:2 + n]]
    right = [value & U64_MASK for value in values[2 + n:]]
    return left, right


def expected_output(values: Sequence[int] | None,
                    output_capacity: int | None = None,
                    output_is_null: bool = False,
                    input_is_null: bool = False,
                    input_length: int | None = None) -> tuple[int, bytes]:
    parsed = _parse(values, input_length, input_is_null)
    if parsed is None:
        return -1, b""
    left, right = parsed
    needed = 8 * (len(left) + len(right) - 1)
    if type(output_is_null) is not bool:
        return -2, b""
    if output_capacity is None:
        output_capacity = MAX_OUTPUT_BYTES
    if type(output_capacity) is not int or output_capacity < 0:
        return -2, b""
    if output_is_null or output_capacity < needed:
        return -2, b""

    result = [0] * (len(left) + len(right) - 1)
    for i, a_value in enumerate(left):
        for j, b_value in enumerate(right):
            result[i + j] ^= _field_product_by_remainder(a_value, b_value)
    return needed, b"".join(value.to_bytes(8, "little") for value in result)
