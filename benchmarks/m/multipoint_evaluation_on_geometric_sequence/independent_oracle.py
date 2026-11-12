"""Repeated Horner evaluation, independent of the chirp-z transform."""

from __future__ import annotations

from collections.abc import Sequence
import struct

try:
    from .primary_oracle import (
        I64_MAX, I64_MIN, INVALID, MAX_INPUT_LENGTH, MAX_M, MAX_N,
        MODULUS, OUTPUT_ERROR,
    )
except ImportError:  # Direct invocation from this package directory.
    from primary_oracle import (
        I64_MAX, I64_MIN, INVALID, MAX_INPUT_LENGTH, MAX_M, MAX_N,
        MODULUS, OUTPUT_ERROR,
    )


def expected_output(
    values: Sequence[int] | None,
    output_capacity: int | None = None,
    output_is_null: bool = False,
    input_is_null: bool = False,
    input_length: int | None = None,
) -> tuple[int, bytes]:
    if type(output_is_null) is not bool or type(input_is_null) is not bool:
        return INVALID, b""
    if input_is_null or not isinstance(values, (list, tuple)) or not 5 <= len(values) <= MAX_INPUT_LENGTH:
        return INVALID, b""
    if input_length is not None and (type(input_length) is not int or input_length != len(values)):
        return INVALID, b""
    if any(type(value) is not int or not I64_MIN <= value <= I64_MAX for value in values):
        return INVALID, b""
    n, m, start, ratio = values[:4]
    if not 1 <= n <= MAX_N or not 1 <= m <= MAX_M or len(values) != 4 + n:
        return INVALID, b""
    coefficients = values[4:]
    if not 0 <= start < MODULUS or not 0 <= ratio < MODULUS:
        return INVALID, b""
    if any(not 0 <= coefficient < MODULUS for coefficient in coefficients):
        return INVALID, b""
    byte_count = 8 * m
    if output_is_null or (output_capacity is not None and
                          (type(output_capacity) is not int or output_capacity < byte_count)):
        return OUTPUT_ERROR, b""
    output = bytearray()
    point = start
    for _ in range(m):
        value = 0
        for coefficient in reversed(coefficients):
            value = (value * point + coefficient) % MODULUS
        output.extend(struct.pack("<q", value))
        point = point * ratio % MODULUS
    return byte_count, bytes(output)
