"""Direct Lagrange-basis evaluation oracle for shifted sample values."""

from __future__ import annotations

from collections.abc import Sequence
import struct

try:
    from .primary_oracle import (
        I64_MAX, I64_MIN, MAX_INPUT_LENGTH, MAX_M, MAX_N, MODULUS,
        OUTPUT_ERROR, INVALID, _mod_pow,
    )
except ImportError:  # Direct invocation from this package directory.
    from primary_oracle import (
        I64_MAX, I64_MIN, MAX_INPUT_LENGTH, MAX_M, MAX_N, MODULUS,
        OUTPUT_ERROR, INVALID, _mod_pow,
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
    if input_is_null or not isinstance(values, (list, tuple)):
        return INVALID, b""
    if len(values) < 4 or len(values) > MAX_INPUT_LENGTH:
        return INVALID, b""
    if input_length is not None and (type(input_length) is not int or input_length != len(values)):
        return INVALID, b""
    if any(type(value) is not int or not I64_MIN <= value <= I64_MAX for value in values):
        return INVALID, b""

    n, m, start = values[:3]
    if not 1 <= n <= MAX_N or not 1 <= m <= MAX_M or len(values) != 3 + n:
        return INVALID, b""
    samples = list(values[3:])
    if not 0 <= start < MODULUS or any(not 0 <= sample < MODULUS for sample in samples):
        return INVALID, b""

    byte_count = 8 * m
    if output_is_null or (output_capacity is not None and
                          (type(output_capacity) is not int or output_capacity < byte_count)):
        return OUTPUT_ERROR, b""

    inverse_denominators: list[int] = []
    for j in range(n):
        denominator = 1
        for t in range(n):
            if t != j:
                denominator = denominator * (j - t) % MODULUS
        inverse_denominators.append(_mod_pow(denominator, MODULUS - 2))

    result: list[int] = []
    for offset in range(m):
        x = (start + offset) % MODULUS
        value = 0
        for j, sample in enumerate(samples):
            numerator = 1
            for t in range(n):
                if t != j:
                    numerator = numerator * (x - t) % MODULUS
            value = (value + sample * numerator * inverse_denominators[j]) % MODULUS
        result.append(value)

    encoded = b"".join(struct.pack("<q", value) for value in result)
    return byte_count, encoded
